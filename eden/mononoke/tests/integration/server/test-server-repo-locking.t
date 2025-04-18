# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This software may be used and distributed according to the terms of the
# GNU General Public License found in the LICENSE file in the root
# directory of this source tree.

  $ . "${TEST_FIXTURES}/library.sh"

  $ INFINITEPUSH_ALLOW_WRITES=true setup_common_config
  $ testtool_drawdag -R repo << EOF
  > A-B-C
  > # bookmark: C master_bookmark
  > EOF
  A=aa53d24251ff3f54b1b2c29ae02826701b2abeb0079f1bb13b8434b54cd87675
  B=f8c75e41a0c4d29281df765f39de47bca1dcadfdc55ada4ccc2f6df567201658
  C=e32a1e342cdb1e38e88466b4c1a01ae9f410024017aa21dc0a1c5da6b3963bf2

  $ start_and_wait_for_mononoke_server

  $ mononoke_admin locking status
  repo                 Unlocked

Lock the repo
  $ mononoke_admin locking lock -R repo --reason "integration test"
  repo locked

Show it is locked
  $ mononoke_admin locking status
  repo                 Locked("integration test")

Can still clone the repo
  $ hg clone -q mono:repo repo
  $ cd repo
  $ enable commitcloud pushrebase
  $ hg checkout -q '.^' 
  $ echo D > D
  $ hg commit -Aqm D

Can still push to commit cloud
  $ hg cloud backup
  commitcloud: head '9c00c53d25b3' hasn't been uploaded yet
  edenapi: queue 1 commit for upload
  edenapi: queue 1 file for upload
  edenapi: uploaded 1 file
  edenapi: queue 1 tree for upload
  edenapi: uploaded 1 tree
  edenapi: uploaded 1 changeset

Cannot push to the server
  $ hg push --to master_bookmark
  pushing rev 9c00c53d25b3 to destination mono:repo bookmark master_bookmark
  searching for changes
  remote: Command failed
  remote:   Error:
  remote:     Repo is locked: integration test
  abort: unexpected EOL, expected netstring digit
  [255]

Unlock the repo
  $ mononoke_admin locking unlock -R repo
  repo unlocked

Now we can push
  $ hg push --to master_bookmark
  pushing rev 9c00c53d25b3 to destination mono:repo bookmark master_bookmark
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  updating bookmark master_bookmark

  $ hg pull -q
  $ tglogp
  @  9c00c53d25b3 draft 'D'
  │
  │ o  1e21255e651f public 'D'
  │ │
  │ o  d3b399ca8757 public 'C'
  ├─╯
  o  80521a640a0c public 'B'
  │
  o  20ca2a4749a4 public 'A'
  
