use thiserror::Error;

#[derive(Error, Debug, Clone, PartialEq, Eq)]
pub enum DomainDbError {
    #[error("Entity or row not found")]
    NotFound,

    #[error("Unique constraint violation: {detail}")]
    UniqueViolation { detail: String },

    #[error("Foreign key constraint violation: {detail}")]
    ForeignKeyViolation { detail: String },

    #[error("MVCC OCC serialization failure (busy snapshot)")]
    SerializationFailure,

    #[error("Database connection error: {0}")]
    ConnectionError(String),

    #[error("Query failed [{code}]: {message}")]
    QueryFailed { code: String, message: String },
}

// Convert Turso / LibSQL errors into domain errors cleanly
impl From<turso::Error> for DomainDbError {
    fn from(err: turso::Error) -> Self {
        match err {
            turso::Error::Busy(_) | turso::Error::BusySnapshot(_) => {
                DomainDbError::SerializationFailure
            }
            turso::Error::QueryReturnedNoRows => DomainDbError::NotFound,
            turso::Error::IoError(kind, op) => {
                DomainDbError::ConnectionError(format!("I/O error ({op}): {kind:?}"))
            }
            turso::Error::Constraint(detail) => {
                // Submatching here is unavoidable - turso merges all constraint types into one variant.
                // The detail string is the only discriminat SQLite exposes.
                if detail.contains("UNIQUE") {
                    DomainDbError::UniqueViolation { detail }
                } else if detail.contains("FOREIGN KEY") {
                    DomainDbError::ForeignKeyViolation { detail }
                } else {
                    DomainDbError::QueryFailed {
                        code: "CONSTRAINT".to_string(),
                        message: detail,
                    }
                }
            }
            other => DomainDbError::QueryFailed {
                code: "ERR_DB".to_string(),
                message: other.to_string(),
            },
        }
    }
}

#[test]
fn busy_maps_to_serialization_failure() {
    let e = DomainDbError::from(turso::Error::Busy("lock".to_string()));
    assert_eq!(e, DomainDbError::SerializationFailure);

    let e = DomainDbError::from(turso::Error::BusySnapshot("snapshot".to_string()));
    assert_eq!(e, DomainDbError::SerializationFailure);
}
