From/Into = infallible; TryFrom/TryInto = fallible with a Result you must handle
as never fails — it truncates silently: 70000 as u16 is 4464, zero complaints
review rule: as on untrusted numbers is a flag; try_from turns overflow into policy
