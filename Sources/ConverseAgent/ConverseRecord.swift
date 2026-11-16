import GraniteAgents

/// The converse agent's place in Granite's roster: an app that links this package finds the `converse` agent by this
/// record, with nothing listed by hand.
@used @section("__DATA_CONST,__granite")
let converseRecord: GraniteRoster.Record = { GraniteRoster.record(ConverseAgent.self) }
