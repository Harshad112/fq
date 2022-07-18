def _bson_torepr:
  def _f:
   ( if .type == null or .type == "array" then
      ( .value.elements
      | map(_f)
      )
     elif .type == "document" then
      ( .value.elements
      | map({key: .name, value: _f})
      | from_entries
      )
     elif .type == "boolean" then .value != 0
     else .value | tovalue
     end
   );
  ( {type: "document", value: .}
  | _f
  );

def _bson__help:
  { examples: [
      {comment: "BSON as JSON", shell: "fq -d bson torepr file"}
    ],
    links: [
      {url: "https://wiki.theory.org/BitTorrentSpecification#Bencoding"}
    ]
  };
