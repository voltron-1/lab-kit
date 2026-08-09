Vector pipeline = source (in) -> transform (reshape/filter) -> sink (out) = Logstash's model
one Event type flows through; a transform can drop, keep, or fan out events
the topology is config-driven (TOML/YAML) and async/tokio underneath — L5.6 at scale
