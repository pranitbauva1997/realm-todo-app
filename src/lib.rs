#[macro_use]
extern crate serde_derive;

#[macro_use]
extern crate askama;

#[macro_use]
extern crate realm_macros;

#[macro_use]
extern crate diesel;

pub mod db;
pub mod reverse;
pub mod routes;
pub mod schema;
