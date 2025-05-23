#!/bin/bash
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ------------------------------------------------------------------------------
#
# tests for command lines (metadata)

source $(dirname "$0")/cmd_test_common.sh || exit

# Input file paths.
INPUT_PNG="${TESTDATA_DIR}/paris_icc_exif_xmp.png"
INPUT_JPG="${TESTDATA_DIR}/paris_exif_xmp_icc.jpg"
INPUT_ICC="${TESTDATA_DIR}/sRGB2014.icc"
# Output file names.
ENCODED_FILE="avif_test_cmd_metadata_encoded.avif"
ENCODED_FILE_NO_METADATA="avif_test_cmd_metadata_encoded_no_metadata.avif"
ENCODED_FILE_MORE_METADATA="avif_test_cmd_metadata_encoded_more_metadata.avif"
DECODED_FILE="avif_test_cmd_metadata_decoded.png"
DECODED_FILE_CHANGED_ICC="avif_test_cmd_metadata_decoded_changed_icc.png"

# Cleanup
cleanup() {
  pushd ${TMP_DIR}
    rm -f -- "${ENCODED_FILE}" "${ENCODED_FILE_NO_METADATA}" \
             "${ENCODED_FILE_MORE_METADATA}" \
             "${DECODED_FILE}" "${DECODED_FILE_CHANGED_ICC}"
  popd
}
trap cleanup EXIT

pushd ${TMP_DIR}
  # Metadata test.
  echo "Testing metadata enc"
  for INPUT in "${INPUT_PNG}" "${INPUT_JPG}"; do
    "${AVIFENC}" "${INPUT}" -o "${ENCODED_FILE}"

    # Ignoring a metadata chunk should produce a different output file.

    "${AVIFENC}" "${INPUT}" -o "${ENCODED_FILE_NO_METADATA}" --ignore-icc
    cmp "${ENCODED_FILE}" "${ENCODED_FILE_NO_METADATA}" && exit 1
    "${AVIFENC}" "${INPUT}" -o "${ENCODED_FILE_NO_METADATA}" --ignore-exif
    cmp "${ENCODED_FILE}" "${ENCODED_FILE_NO_METADATA}" && exit 1
    "${AVIFENC}" "${INPUT}" -o "${ENCODED_FILE_NO_METADATA}" --ignore-xmp
    cmp "${ENCODED_FILE}" "${ENCODED_FILE_NO_METADATA}" && exit 1

    "${AVIFDEC}" "${ENCODED_FILE}" "${DECODED_FILE}"
    "${AVIFDEC}" "${ENCODED_FILE}" --ignore-icc "${DECODED_FILE_CHANGED_ICC}"
    cmp "${DECODED_FILE}" "${DECODED_FILE_CHANGED_ICC}" && exit 1
    "${AVIFDEC}" "${ENCODED_FILE}" --icc "${INPUT_ICC}" "${DECODED_FILE_CHANGED_ICC}"
    cmp "${DECODED_FILE}" "${DECODED_FILE_CHANGED_ICC}" && exit 1

    # As should adding metadata.

    "${AVIFENC}" "${INPUT}" -o "${ENCODED_FILE_MORE_METADATA}" --clli 1000,50
    cmp "${ENCODED_FILE}" "${ENCODED_FILE_MORE_METADATA}" && exit 1
  done
popd

exit 0
