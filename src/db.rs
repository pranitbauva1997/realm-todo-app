pub use realm::base::*;

pub fn add_todo_db(in_: &In0, title: String, done: i32) -> Result<()> {
    use crate::schema::hello_todo;
    use diesel::prelude::*;

    diesel::insert_into(hello_todo::table)
        .values((hello_todo::title.eq(title), hello_todo::done.eq(done)))
        .execute(in_.conn)
        .map(|_| ())
        .map_err(Into::into)
}

pub fn get_all_todos(in_: &In0) -> Result<Vec<crate::routes::index::Item>> {
    use crate::schema::hello_todo;
    use diesel::prelude::*;

    let rows: Result<Vec<(String, i32)>> = hello_todo::table
        .select((hello_todo::title, hello_todo::done))
        .load(in_.conn)
        .map_err(Into::into);

    match rows {
        Ok(r) => Ok(r
            .into_iter()
            .map(|item| crate::routes::index::Item {
                title: item.0,
                done: item.1 != 0,
            })
            .collect()),
        Err(er) => Err(er),
    }
}
