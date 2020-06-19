pub use realm::base::*;

pub fn increment(in_: &In0) -> Result<()> {
    use crate::schema::hello_counter;
    use diesel::prelude::*;

    diesel::update(hello_counter::table)
        .set(hello_counter::count.eq(hello_counter::count + 1))
        .execute(in_.conn)
        .map(|_| ())
        .map_err(Into::into)
}

pub fn get_count(in_: &In0) -> Result<i32> {
    use crate::schema::hello_counter;
    use diesel::prelude::*;

    if let Ok(count) = hello_counter::table
        .select(hello_counter::count)
        .first(in_.conn)
    {
        return Ok(count);
    };

    diesel::insert_into(hello_counter::table)
        .values(hello_counter::count.eq(0))
        .execute(in_.conn)?;

    Ok(0)
}
