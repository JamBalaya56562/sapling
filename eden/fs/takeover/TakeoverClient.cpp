/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This software may be used and distributed according to the terms of the
 * GNU General Public License version 2.
 */

#ifndef _WIN32

#include "eden/fs/takeover/TakeoverClient.h"

#include <folly/io/Cursor.h>
#include <folly/io/async/EventBase.h>
#include <folly/logging/xlog.h>
#include <thrift/lib/cpp2/protocol/Serializer.h>
#include "eden/common/utils/FaultInjector.h"
#include "eden/common/utils/FutureUnixSocket.h"
#include "eden/fs/takeover/TakeoverData.h"
#include "eden/fs/takeover/gen-cpp2/takeover_types.h"

using apache::thrift::CompactSerializer;
using std::string;

namespace facebook::eden {

TakeoverData takeoverMounts(
    AbsolutePathPiece socketPath,
    const std::chrono::seconds& takeoverReceiveTimeout,
    bool shouldThrowDuringTakeover,
    bool shouldPing,
    const std::set<int32_t>& supportedVersions,
    const uint64_t supportedTakeoverCapabilities) {
  folly::EventBase evb;
  folly::exception_wrapper expectedException;
  TakeoverData takeoverData;

  auto connectTimeout = std::chrono::seconds(1);
  FutureUnixSocket socket;
  socket.connect(&evb, socketPath.view(), connectTimeout)
      .thenValue(
          [&socket, supportedVersions, supportedTakeoverCapabilities](auto&&) {
            // Send our protocol version so that the server knows
            // whether we're capable of handshaking successfully

            TakeoverVersionQuery query;
            query.versions_ref() = supportedVersions;
            query.capabilities_ref() = supportedTakeoverCapabilities;

            return socket.send(
                CompactSerializer::serialize<folly::IOBufQueue>(query).move());
          })
      .thenValue([&socket, &takeoverReceiveTimeout](auto&&) {
        // Wait for a response. this will either be a "ready" ping or the
        // takeover data depending on the server protocol
        return socket.receive(takeoverReceiveTimeout);
      })
      .thenValue([&socket,
                  shouldPing,
                  shouldThrowDuringTakeover,
                  &takeoverReceiveTimeout](UnixSocket::Message&& msg) mutable {
        if (TakeoverData::isPing(&msg.data)) {
          if (shouldPing) {
            // Just send an empty message back here, the server knows it sent a
            // ping so it does not need to parse the message.
            UnixSocket::Message ping;
            return socket.send(std::move(ping))
                .thenValue([&socket,
                            shouldThrowDuringTakeover,
                            &takeoverReceiveTimeout](auto&&) mutable {
                  // Possibly simulate a takeover error during data transfer
                  // for testing purposes. While we would prefer to use
                  // fault injection here, it's not possible to inject an
                  // error into the TakeoverClient because the thrift server
                  // is not yet running.
                  if (shouldThrowDuringTakeover) {
                    // throw std::runtime_error("simulated takeover error");
                    return folly::makeFuture<UnixSocket::Message>(
                        folly::exception_wrapper(
                            std::runtime_error("simulated takeover error")));
                  }
                  // Wait for the takeover data response
                  return socket.receive(takeoverReceiveTimeout);
                });
          } else {
            // This should only be hit during integration tests.
            return folly::makeFuture<UnixSocket::Message>(
                folly::exception_wrapper(std::runtime_error(
                    "ping received but should not respond")));
          }
        } else {
          // Older versions of EdenFS will not send a "ready" ping and
          // could simply send the takeover data.
          return folly::makeFuture<UnixSocket::Message>(std::move(msg));
        }
      })
      .thenValue([&takeoverData](UnixSocket::Message&& msg) {
        if (TakeoverData::isFirstChunk(&msg.data)) {
          // Not Implemented Yet
        } else {
          for (auto& file : msg.files) {
            XLOGF(DBG7, "received fd for takeover: {}", file.fd());
          }
          takeoverData = TakeoverData::deserialize(msg);
        }
      })
      .thenError([&expectedException](folly::exception_wrapper&& ew) {
        expectedException = std::move(ew);
      })
      .ensure([&evb] { evb.terminateLoopSoon(); });

  evb.loop();

  if (expectedException) {
    XLOGF(ERR, "error receiving takeover data: {}", expectedException.what());
    expectedException.throw_exception();
  }

  return takeoverData;
}
} // namespace facebook::eden

#endif
