import LeanRDF.Text.Hash

/-!
# Hash functions

SPARQL's `MD5`, `SHA1`, `SHA256`, `SHA384` and `SHA512` (§17.4.6) use the hash functions of the
core package (`LeanRDF.Text.Hash`), which RDFC-1.0 and graph digests share.
-/

namespace LeanRDF.Sparql.Hash

export LeanRDF.Hash (md5 sha1 sha256 sha384 sha512)

end LeanRDF.Sparql.Hash
