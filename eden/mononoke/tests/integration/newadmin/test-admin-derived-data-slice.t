# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This software may be used and distributed according to the terms of the
# GNU General Public License found in the LICENSE file in the root
# directory of this source tree.
#require slow

  $ . "${TEST_FIXTURES}/library.sh"

setup configuration
  $ setup_common_config
  $ mononoke_testtool drawdag -R repo <<'EOF'
  >      G
  >      |
  >      F
  >     / \
  >    D   E     L
  >     \ /      |
  >      C       K
  >      |  H    |
  >      B /     J
  >      |/      |
  >      A       I
  > # bookmark: G first_bookmark
  > # bookmark: L second_bookmark
  > EOF
  A=aa53d24251ff3f54b1b2c29ae02826701b2abeb0079f1bb13b8434b54cd87675
  B=f8c75e41a0c4d29281df765f39de47bca1dcadfdc55ada4ccc2f6df567201658
  C=e32a1e342cdb1e38e88466b4c1a01ae9f410024017aa21dc0a1c5da6b3963bf2
  D=f41e886d61d03021b73d006acf237244086eb7a5d9c7989e44e59b76d3c3f2b5
  E=c4300546b70e88ad3c00bc1014c68a182782d089cadb54fec05b1d8790580c3a
  F=2c1fe61358291c356cf3367b66152fca1f3ee8e9e4a5129f59643100f91408f7
  G=417bd860e802f264f4b5cbdcf0cf14baf9c8ae6d6a1beedafbf02d44c7e4063d
  H=9cff72783886d8e1c03fc9420fe944b30e30f0518c2fbb65ea04bca9b7f880c0
  I=19fff6751f630d5c837e00b7b28260825b53e4160aa5c8b3f5067e9f1eb376a4
  J=48e9ea18a97b9d86bcb0f209d76313b2597c05fecf2cb0ba16f595f4d24c4355
  K=a461eb57dda3f53be7fc7056af3637eb235280191fe002c4f6675201508011ff
  L=e344c3733985ad4321993aba435251774ed2107b2f2f250a1acd32db374ec5c3

slice all ancestors of all bookmarks
  $ mononoke_admin derived-data -R repo slice -T test_manifests --slice-size 3 --all-bookmarks
  Slices:
  a461eb57dda3f53be7fc7056af3637eb235280191fe002c4f6675201508011ff->19fff6751f630d5c837e00b7b28260825b53e4160aa5c8b3f5067e9f1eb376a4
  e344c3733985ad4321993aba435251774ed2107b2f2f250a1acd32db374ec5c3->e344c3733985ad4321993aba435251774ed2107b2f2f250a1acd32db374ec5c3 f8c75e41a0c4d29281df765f39de47bca1dcadfdc55ada4ccc2f6df567201658->aa53d24251ff3f54b1b2c29ae02826701b2abeb0079f1bb13b8434b54cd87675
  c4300546b70e88ad3c00bc1014c68a182782d089cadb54fec05b1d8790580c3a->e32a1e342cdb1e38e88466b4c1a01ae9f410024017aa21dc0a1c5da6b3963bf2 f41e886d61d03021b73d006acf237244086eb7a5d9c7989e44e59b76d3c3f2b5->f41e886d61d03021b73d006acf237244086eb7a5d9c7989e44e59b76d3c3f2b5
  417bd860e802f264f4b5cbdcf0cf14baf9c8ae6d6a1beedafbf02d44c7e4063d->2c1fe61358291c356cf3367b66152fca1f3ee8e9e4a5129f59643100f91408f7
  Boundary changesets:
  a461eb57dda3f53be7fc7056af3637eb235280191fe002c4f6675201508011ff
  c4300546b70e88ad3c00bc1014c68a182782d089cadb54fec05b1d8790580c3a
  f41e886d61d03021b73d006acf237244086eb7a5d9c7989e44e59b76d3c3f2b5
  f8c75e41a0c4d29281df765f39de47bca1dcadfdc55ada4ccc2f6df567201658

write output to a json file
  $ mononoke_admin derived-data -R repo slice -T test_manifests --slice-size 3 --all-bookmarks -o slices.json
  $ cat slices.json | jq .
  [
    [
      {
        "segments": [
          {
            "head": "a461eb57dda3f53be7fc7056af3637eb235280191fe002c4f6675201508011ff",
            "base": "19fff6751f630d5c837e00b7b28260825b53e4160aa5c8b3f5067e9f1eb376a4"
          }
        ]
      },
      {
        "segments": [
          {
            "head": "e344c3733985ad4321993aba435251774ed2107b2f2f250a1acd32db374ec5c3",
            "base": "e344c3733985ad4321993aba435251774ed2107b2f2f250a1acd32db374ec5c3"
          },
          {
            "head": "f8c75e41a0c4d29281df765f39de47bca1dcadfdc55ada4ccc2f6df567201658",
            "base": "aa53d24251ff3f54b1b2c29ae02826701b2abeb0079f1bb13b8434b54cd87675"
          }
        ]
      },
      {
        "segments": [
          {
            "head": "c4300546b70e88ad3c00bc1014c68a182782d089cadb54fec05b1d8790580c3a",
            "base": "e32a1e342cdb1e38e88466b4c1a01ae9f410024017aa21dc0a1c5da6b3963bf2"
          },
          {
            "head": "f41e886d61d03021b73d006acf237244086eb7a5d9c7989e44e59b76d3c3f2b5",
            "base": "f41e886d61d03021b73d006acf237244086eb7a5d9c7989e44e59b76d3c3f2b5"
          }
        ]
      },
      {
        "segments": [
          {
            "head": "417bd860e802f264f4b5cbdcf0cf14baf9c8ae6d6a1beedafbf02d44c7e4063d",
            "base": "2c1fe61358291c356cf3367b66152fca1f3ee8e9e4a5129f59643100f91408f7"
          }
        ]
      }
    ],
    [
      "a461eb57dda3f53be7fc7056af3637eb235280191fe002c4f6675201508011ff",
      "c4300546b70e88ad3c00bc1014c68a182782d089cadb54fec05b1d8790580c3a",
      "f41e886d61d03021b73d006acf237244086eb7a5d9c7989e44e59b76d3c3f2b5",
      "f8c75e41a0c4d29281df765f39de47bca1dcadfdc55ada4ccc2f6df567201658"
    ]
  ]

slice ancestors of only the first bookmark
  $ mononoke_admin derived-data -R repo slice -T test_manifests --slice-size 3 -B first_bookmark
  Slices:
  e32a1e342cdb1e38e88466b4c1a01ae9f410024017aa21dc0a1c5da6b3963bf2->aa53d24251ff3f54b1b2c29ae02826701b2abeb0079f1bb13b8434b54cd87675
  c4300546b70e88ad3c00bc1014c68a182782d089cadb54fec05b1d8790580c3a->c4300546b70e88ad3c00bc1014c68a182782d089cadb54fec05b1d8790580c3a f41e886d61d03021b73d006acf237244086eb7a5d9c7989e44e59b76d3c3f2b5->f41e886d61d03021b73d006acf237244086eb7a5d9c7989e44e59b76d3c3f2b5 2c1fe61358291c356cf3367b66152fca1f3ee8e9e4a5129f59643100f91408f7->2c1fe61358291c356cf3367b66152fca1f3ee8e9e4a5129f59643100f91408f7
  417bd860e802f264f4b5cbdcf0cf14baf9c8ae6d6a1beedafbf02d44c7e4063d->417bd860e802f264f4b5cbdcf0cf14baf9c8ae6d6a1beedafbf02d44c7e4063d
  Boundary changesets:
  2c1fe61358291c356cf3367b66152fca1f3ee8e9e4a5129f59643100f91408f7
  e32a1e342cdb1e38e88466b4c1a01ae9f410024017aa21dc0a1c5da6b3963bf2

slice ancestors of the first bookmark after deriving C and its ancestors
  $ mononoke_admin derived-data -R repo derive -T test_manifests -i e32a1e342cdb1e38e88466b4c1a01ae9f410024017aa21dc0a1c5da6b3963bf2
  $ mononoke_admin derived-data -R repo slice -T test_manifests --slice-size 3 -B first_bookmark
  Slices:
  f41e886d61d03021b73d006acf237244086eb7a5d9c7989e44e59b76d3c3f2b5->f41e886d61d03021b73d006acf237244086eb7a5d9c7989e44e59b76d3c3f2b5 c4300546b70e88ad3c00bc1014c68a182782d089cadb54fec05b1d8790580c3a->c4300546b70e88ad3c00bc1014c68a182782d089cadb54fec05b1d8790580c3a 2c1fe61358291c356cf3367b66152fca1f3ee8e9e4a5129f59643100f91408f7->2c1fe61358291c356cf3367b66152fca1f3ee8e9e4a5129f59643100f91408f7
  417bd860e802f264f4b5cbdcf0cf14baf9c8ae6d6a1beedafbf02d44c7e4063d->417bd860e802f264f4b5cbdcf0cf14baf9c8ae6d6a1beedafbf02d44c7e4063d
  Boundary changesets:
  2c1fe61358291c356cf3367b66152fca1f3ee8e9e4a5129f59643100f91408f7
