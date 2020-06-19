pub use realm::base::*;

pub fn get(in_: &In0) -> realm::Result {
    crate::db::increment(in_)?;
    crate::routes::index::redirect(in_)
}
