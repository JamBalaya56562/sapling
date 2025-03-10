/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This software may be used and distributed according to the terms of the
 * GNU General Public License version 2.
 */

use mononoke_types::ContentId;
use mononoke_types::RepoPath;
use thiserror::Error;

use crate::HgFileNodeId;
use crate::HgNodeHash;
use crate::Type;

#[derive(Debug, Error)]
pub enum MononokeHgBlobError {
    #[error("Corrupt hg filenode returned: {expected} != {actual}")]
    CorruptHgFileNode {
        expected: HgFileNodeId,
        actual: HgFileNodeId,
    },
    #[error("Content blob missing for id: {0}")]
    ContentBlobMissing(ContentId),
    #[error("Mercurial content missing for node {0} (type {1})")]
    HgContentMissing(HgNodeHash, Type),
    #[error("Error while deserializing file node retrieved from key '{0}'")]
    FileNodeDeserializeFailed(String),
    #[error("Error while deserializing manifest retrieved from key '{0}'")]
    ManifestDeserializeFailed(String),
    #[error("Incorrect LFS file content {0}")]
    IncorrectLfsFileContent(String),
    #[error("Inconsistent node hash for entry: path {0}, provided: {1}, computed: {2}")]
    InconsistentEntryHashForPath(RepoPath, HgNodeHash, HgNodeHash),
    #[error("Inconsistent node hash for entry: provided: {0}, computed: {1}")]
    InconsistentEntryHash(HgNodeHash, HgNodeHash),
    #[error("Inconsistent computed node hash override for entry: provided: {0}, computed: {1}")]
    InconsistentComputedEntryHash(HgNodeHash, HgNodeHash),
}
