// ========== Storage 后端适配器

// 文件记录
struct FileRecord {
  name: String
  data: String
  size: Int
}

// ========== Mock Storage 后端

struct MockStorageBackend {
  initialized: Bool
  files: Array[FileRecord]
}

fn MockStorageBackend::new() -> MockStorageBackend {
  MockStorageBackend {
    initialized: false,
    files: [],
  }
}

fn MockStorageBackend::name() -> String {
  "mock"
}

fn MockStorageBackend::init(self) -> Result[Unit, String] {
  self.initialized = true
  println("[StorageMock] Initialized (in-memory)")
  Ok(())
}

fn MockStorageBackend::writeFile(self, name: String, data: String) -> Result[Unit, String] {
  if !self.initialized {
    return Err("Storage not initialized")
  }
  
  let mut found = false
  let mut newFiles: Array[FileRecord] = []
  for file in self.files {
    if file.name == name {
      found = true
      newFiles.push(FileRecord {
        name: name,
        data: data,
        size: data.length(),
      })
    } else {
      newFiles.push(file)
    }
  }
  
  if !found {
    newFiles.push(FileRecord {
      name: name,
      data: data,
      size: data.length(),
    })
  }
  
  self.files = newFiles
  println("[StorageMock] Wrote file: " + name + " (" + data.length().toString() + " bytes)")
  Ok(())
}

fn MockStorageBackend::readFile(self, name: String) -> Result[String, String] {
  if !self.initialized {
    return Err("Storage not initialized")
  }
  
  for file in self.files {
    if file.name == name {
      println("[StorageMock] Read file: " + name)
      return Ok(file.data)
    }
  }
  
  Err("File not found: " + name)
}

fn MockStorageBackend::listFiles(self) -> Result[Array[String], String] {
  if !self.initialized {
    return Err("Storage not initialized")
  }
  
  let mut result: Array[String] = []
  for file in self.files {
    result.push(file.name)
  }
  Ok(result)
}

fn MockStorageBackend::cleanup(self) -> Unit {
  self.initialized = false
  self.files = []
  println("[StorageMock] Cleaned up")
}

// ========== POSIX Storage 后端（占位）

struct PosixStorageBackend {
  initialized: Bool
}

fn PosixStorageBackend::new() -> PosixStorageBackend {
  PosixStorageBackend { initialized: false }
}

fn PosixStorageBackend::name() -> String {
  "posix"
}

fn PosixStorageBackend::init(self) -> Result[Unit, String] {
  self.initialized = true
  println("[StoragePOSIX] Initialized (placeholder implementation)")
  Ok(())
}

fn PosixStorageBackend::writeFile(self, name: String, data: String) -> Result[Unit, String] {
  if !self.initialized {
    return Err("Storage not initialized")
  }
  Err("POSIX backend not implemented yet - use mock backend")
}

fn PosixStorageBackend::readFile(self, name: String) -> Result[String, String] {
  if !self.initialized {
    return Err("Storage not initialized")
  }
  Err("POSIX backend not implemented yet - use mock backend")
}

fn PosixStorageBackend::listFiles(self) -> Result[Array[String], String] {
  if !self.initialized {
    return Err("Storage not initialized")
  }
  Err("POSIX backend not implemented yet - use mock backend")
}

fn PosixStorageBackend::cleanup(self) -> Unit {
  self.initialized = false
}

// ========== In-Memory Storage 后端（占位）

struct InMemoryStorageBackend {
  initialized: Bool
}

fn InMemoryStorageBackend::new() -> InMemoryStorageBackend {
  InMemoryStorageBackend { initialized: false }
}

fn InMemoryStorageBackend::name() -> String {
  "inmemory"
}

fn InMemoryStorageBackend::init(self) -> Result[Unit, String] {
  self.initialized = true
  println("[StorageInMemory] Initialized (placeholder implementation)")
  Ok(())
}

fn InMemoryStorageBackend::writeFile(self, name: String, data: String) -> Result[Unit, String] {
  if !self.initialized {
    return Err("Storage not initialized")
  }
  Err("In-memory backend not implemented yet - use mock backend")
}

fn InMemoryStorageBackend::readFile(self, name: String) -> Result[String, String] {
  if !self.initialized {
    return Err("Storage not initialized")
  }
  Err("In-memory backend not implemented yet - use mock backend")
}

fn InMemoryStorageBackend::listFiles(self) -> Result[Array[String], String] {
  if !self.initialized {
    return Err("Storage not initialized")
  }
  Err("In-memory backend not implemented yet - use mock backend")
}

fn InMemoryStorageBackend::cleanup(self) -> Unit {
  self.initialized = false
}
