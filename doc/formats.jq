#!/usr/bin/env fq -rnf

def code: "`\(.)`";
def nbsp: gsub(" "; "&nbsp;");
def has_section($f; $fhelp): $fhelp.notes or $fhelp.examples or $fhelp.links or $f.decode_in_arg;

def formats_list:
  [ formats
  | to_entries[] as {$key, $value}
  | (_format_func($key; "_help")? // {}) as $fhelp
  | if has_section($value; $fhelp) then "[\($key)](doc/formats.md#\($key))"
    else $key
    end
  ] | join(",\n");

def formats_table:
  ( [ {
        name: "Name",
        desc: "Description",
        uses: "Dependencies"
      },
      {
        name: "-",
        desc: "-",
        uses: "-"
      },
      ( formats
      | to_entries[]
      | (_format_func(.key; "_help")? // {}) as $fhelp
      | {
          name:
            ( ( .key as $format
              | if has_section(.value; $fhelp) then "[\($format | code)](#\($format))"
                else $format | code
                end
              )
            + " "
            ),
          desc: (.value.description | nbsp),
          uses: "<sub>\((((.value.dependencies | flatten | map(code)) | join(" "))? // ""))</sub>"
        }
      ),
      ( [ formats
        | to_entries[]
        | . as $e
        | select(.value.groups)
        | .value.groups[] | {key: ., value: $e.key}
        ]
      | reduce .[] as $e ({}; .[$e.key] += [$e.value])
      | to_entries[]
      | {
          name: ((.key | code) + " "),
          desc: "Group",
          uses: "<sub>\(((.value | map(code)) | join(" ")))</sub>"
        }
      )
    ]
  | table(
      [ .name
      , .desc
      , .uses
      ];
      [ ""
      , (.[0] | . as $rc | $rc.string | rpad(" "; $rc.maxwidth))
      , (.[1] | . as $rc | $rc.string | rpad(" "; $rc.maxwidth))
      , .[2].string
      , ""
      ] | join("|")
    )
  );

def formats_sections:
  ( formats[] as $f
  | (_format_func($f.name; "_help")? // {} | _help_format_enrich("fq"; $f; false)) as $fhelp
  | select(has_section($f; $fhelp))
  | "### \($f.name)"
  , ""
  , ($fhelp.notes | if . then ., "" else empty end)
  , if $f.decode_in_arg then
      ( "#### Options"
      , ""
      , ( [ { name: "Name"
            , default: "Default"
            , desc: "Description"
            }
          , { name: "-"
            , default: "-"
            , desc: "-"
            }
          , ( $f.decode_in_arg
            | to_entries[] as {$key,$value}
            | { name: ($key | code)
              , default: ($value | tostring)
              , desc: $f.decode_in_arg_doc[$key]
              }
            )
          ]
        | table(
            [ .name
            , .default
            , .desc
            ];
            [ ""
            , (.[0] | . as $rc | $rc.string | rpad(" "; $rc.maxwidth))
            , (.[1] | . as $rc | $rc.string | rpad(" "; $rc.maxwidth))
            , .[2].string
            , ""
            ] | join("|")
          )
        )
      , ""
      )
    else empty
    end
  , if $fhelp.examples then
      ( "#### Examples"
      , ""
      , ( $fhelp.examples[]
        | "\(.comment)"
        , if .shell then
            ( "```"
            , "$ \(.shell)"
            , "```"
            )
          elif .expr then
            ( "```"
            , "... | \(.expr)"
            , "```"
            )
          else empty
          end
        , ""
        )
    )
    else empty
    end
  , if $fhelp.links then
      ( "#### References and links"
      , ""
      , ( $fhelp.links[]
        | if .title then "- [\(.title)](\(.url))"
          else "- \(.url)"
          end
        )
      , ""
      )
    else empty
    end
  );
