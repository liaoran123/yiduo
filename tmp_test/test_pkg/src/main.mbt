enum MyEnum {
  MyVariant {
    field1: Int
    field2: String
  }
}

fn MyEnum::process(self) -> Int {
  match self {
    MyVariant { field1, field2 } => field1
  }
}

fn main {
  let x = MyEnum::MyVariant { field1: 42, field2: "hello" }
  println(x.process().to_string())
}