//===---- QASMIncludeResolver.cpp -  OpenQASM Include Resolution --------===//
//
// @author  Lars Schütze (lars.schuetze@tu-dresden.de)
//===----------------------------------------------------------------------===//

// frontend/qasm/common/QASMIncludeResolver.cpp

#include "QASMIncludeResolver.h"

#include <llvm/ADT/SmallString.h>
#include <llvm/Support/MemoryBuffer.h>
#include <llvm/Support/Path.h>

namespace quantum::frontend {

void QASMIncludeResolver::addBuiltin(
    llvm::StringRef name,
    llvm::StringRef source,
    llvm::StringRef logicalFilename)
{
    builtins.try_emplace(
        name,
        ResolvedInclude{
            .filename = logicalFilename.str(),
            .source = source.str(),
        });
}

void QASMIncludeResolver::addSearchPath(llvm::StringRef path)
{ searchPaths.push_back(path.str()); }

static llvm::Expected<ResolvedInclude> readIncludeFile(llvm::StringRef path)
{
    auto buffer = llvm::MemoryBuffer::getFile(path);

    if (!buffer) {
        return llvm::createStringError(
            buffer.getError(),
            "cannot open include file '%s'",
            path.str().c_str());
    }

    return ResolvedInclude{
        .filename = path.str(),
        .source = (*buffer)->getBuffer().str(),
    };
}

llvm::Expected<ResolvedInclude> QASMIncludeResolver::resolve(
    llvm::StringRef includeName,
    llvm::StringRef includingFile) const
{
    // 1. Built-in resources have precedence.
    if (auto it = builtins.find(includeName); it != builtins.end())
        return it->second;

    // 2. Resolve relative to the including file.
    //
    // Ignore synthetic filenames such as "<qelib1.inc>".
    if (!includingFile.empty() && !includingFile.starts_with("<")) {

        llvm::SmallString<256> path(includingFile);
        llvm::sys::path::remove_filename(path);
        llvm::sys::path::append(path, includeName);

        if (auto result = readIncludeFile(path))
            return result;
        else
            llvm::consumeError(result.takeError());
    }

    // 3. Search explicitly configured include directories.
    for (const std::string &searchPath : searchPaths) {
        llvm::SmallString<256> path(searchPath);
        llvm::sys::path::append(path, includeName);

        if (auto result = readIncludeFile(path))
            return result;
        else
            llvm::consumeError(result.takeError());
    }

    return llvm::createStringError(
        llvm::inconvertibleErrorCode(),
        "could not resolve include '%s'",
        includeName.str().c_str());
}

} // namespace quantum::frontend
