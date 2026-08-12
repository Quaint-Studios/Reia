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
        let err_str = err.to_string();

        if err_str.contains("SQLITE_BUSY")
            || err_str.contains("serialization")
            || err_str.contains("40001")
        {
            DomainDbError::SerializationFailure
        } else if err_str.contains("UNIQUE constraint") {
            DomainDbError::UniqueViolation { detail: err_str }
        } else if err_str.contains("FOREIGN KEY constraint") {
            DomainDbError::ForeignKeyViolation { detail: err_str }
        } else {
            DomainDbError::QueryFailed {
                code: "ERR_DB".to_string(),
                message: err_str,
            }
        }
    }
}
