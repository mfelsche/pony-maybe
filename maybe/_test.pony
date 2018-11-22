use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_MaybeTestVal)
    test(_MaybeTestIso)

class iso _MaybeTestVal is UnitTest
  fun name(): String => "maybe/val"

  fun apply(h: TestHelper) ? =>
    let maybe_string_some: Maybe[String] = "some"
    let maybe_string_none: Maybe[String] = None

    // get
    h.assert_eq[String](Opt.get[String](maybe_string_some, "noes"), "some")
    h.assert_eq[String](Opt.get[String](maybe_string_none, "yes"), "yes")

    // map
    let get_length: {(String): USize} = {(s: String): USize => s.size() }
    match Opt.map[String, USize](maybe_string_some, get_length)
    | None => h.fail("None from defined Maybe")
    end

    match Opt.map[String, USize](maybe_string_none, get_length)
    | let s: USize => h.fail("undefined Maybe suddenly has a value")
    end

    // flat_map
    let get_stuff: {(String): Maybe[String]} =
      {(s: String): Maybe[String] => if s.contains("so") then "indeed" end }
    match Opt.flat_map[String, String](maybe_string_some, get_stuff)
    | "indeed" => h.log("flat_map OK")
    else
      h.fail("flat_map should have kept a defined value here")
    end

    match Opt.flat_map[String, String]("bla", get_stuff)
    | None => h.log("flat_map defined->None OK")
    else
      h.fail("flat_map should have produced None here")
    end

    match Opt.flat_map[String, String](maybe_string_none, get_stuff)
    | None => h.log("flat_map None->None OK")
    else
      h.fail("flat_map should have kept None here")
    end

    // filter
    let non_empty: {(String): (Bool, String)} = {(s) => (s.size() > 0, s) }
    match Opt.filter[String](maybe_string_some, non_empty)
    | "some" => h.log("filter OK")
    else
      h.fail("filter should keep non-matching value")
    end

    match Opt.filter[String]("", non_empty)
    | None => h.log("filter match OK")
    else
      h.fail("filter should be applied to return a None")
    end

    match Opt.filter[String](maybe_string_none, non_empty)
    | None => h.log("filter None->None OK")
    else
      h.fail("filter should be keep None")
    end

    // apply
    h.expect_action("apply some")
    Opt.apply[String](maybe_string_some, {(s) => h.complete_action("apply some")})
    Opt.apply[String](maybe_string_none, {(s) => h.fail("apply on None should never be called")})

    // force
    h.assert_error({()? => Opt.force[String](maybe_string_none)? })
    h.assert_eq[String](Opt.force[String](maybe_string_some)?, "some")

    // iter
    let some_iter = Opt.iter[String](maybe_string_some)
    h.assert_true(some_iter.has_next())
    some_iter.next()?
    h.assert_false(some_iter.has_next())

    h.assert_false(Opt.iter[String](maybe_string_none).has_next())


class Foo is (Equatable[Foo] & Stringable)
  let x: USize
  new iso create(x': USize) =>
    x = x'

  fun eq(that: box->Foo): Bool =>
    this.x.eq(that.x)

  fun string(): String iso^ =>
    recover
      String()
        .>append("Foo(")
        .>append(x.string())
        .>append(")")
    end


class _MaybeTestIso is UnitTest
  fun name(): String => "maybe/iso"

  fun foo(i: USize = 0): Foo iso^ => recover iso Foo(i) end

  fun apply(h: TestHelper) ? =>
    // get
    h.assert_true(Opt.get[Foo iso](foo(0), foo(1)) == foo(0))
    h.assert_true(Opt.get[Foo iso](None, foo(1)) == foo(1))

    // map
    let get_x: {(Foo iso): USize} = {(foo): USize => foo.x }
    match Opt.map[Foo iso, USize](foo(1), get_x)
    | USize(1) => h.log("map OK")
    else
      h.fail("no value mapped from defined maybe")
    end

    match Opt.map[Foo iso, USize](None, get_x)
    | None => h.log("map None OK")
    else
      h.fail("undefined Maybe suddenly has a value")
    end

    match Opt.map[Foo iso, Foo iso](foo(1), {(foo) => Foo(foo.x + 1) })
    | Foo(2) => h.log("map to iso OK")
    else
      h.fail("map to iso failed")
    end

    // flat_map
    let multiply_odd: {(Foo iso): Maybe[Foo iso^]} =
      {(f: Foo iso): Maybe[Foo iso^] => if (f.x % 2) != 0 then Foo(f.x * 2) end }

    match Opt.flat_map[Foo iso, Foo iso](foo(5), multiply_odd)
    | Foo(10) => h.log("flat_map OK")
    else
      h.fail("flat_map should have kept a defined value here")
    end

    match Opt.flat_map[Foo iso, Foo iso](foo(8), multiply_odd)
    | None => h.log("flat_map defined->None OK")
    else
      h.fail("flat_map should have produced None here")
    end

    match Opt.flat_map[Foo iso, Foo iso](None, multiply_odd)
    | None => h.log("flat_map None->None OK")
    else
      h.fail("flat_map should have kept None here")
    end

    // filter
    let not_null: {(Foo iso): (Bool, Foo iso^)} = {
      (foo) =>
        let res: Bool = foo.x != 0
        (res, consume foo)
      }
    match Opt.filter[Foo iso](foo(1), not_null)
    | Foo(1) => h.log("filter OK")
    else
      h.fail("filter should keep non-matching value")
    end

    match Opt.filter[Foo iso](foo(0), not_null)
    | None => h.log("filter match OK")
    else
      h.fail("filter should be applied to return a None")
    end

    match Opt.filter[Foo iso](None, not_null)
    | None => h.log("filter None->None OK")
    else
      h.fail("filter should be keep None")
    end

    // apply
    h.expect_action("apply 1")
    Opt.apply[Foo iso](foo(1), {(foo) => h.complete_action("apply " + foo.x.string())})
    Opt.apply[Foo iso](None, {(s) => h.fail("apply on None should never be called")})

    // force
    h.assert_error({()? => Opt.force[Foo iso]( None)? })
    h.assert_true(Opt.force[Foo iso](Foo(1))? == Foo(1))

    // iter
    let some_iter = Opt.iter[Foo iso](foo(42))
    h.assert_true(some_iter.has_next())
    let f: Foo iso = some_iter.next()?
    h.assert_false(some_iter.has_next())

    h.assert_false(Opt.iter[Foo iso](None).has_next())

