local net = require("@lune/net")
local serde = require("@lune/serde")
local process = require("@lune/process")
local stdio = require("@lune/stdio")
local unzip = require("./luau_packages/unzip")
local dirs = require("./lune_packages/dirs")
local pathfs = require("./lune_packages/pathfs")
local fs = pathfs.fs

local TYPEDEFS_PATH_FORMAT = "%s/.lune/.typedefs/%s/"
local DOWNLOAD_LUNE_SOURCE_URL_FORMAT = "https://api.github.com/repos/lune-org/lune/zipball/v%s"
local DEFAULT_LUAURC_CONTENTS = [[{
	"aliases": {
		"lune": "%s"
	}
}
]]
local ERROR_PREFIX = `{stdio.color("red")}{stdio.style("bold")}error{stdio.color("reset")}:`

local luneVersion = process.args[1]
if not luneVersion then
	luneVersion = (_VERSION :: string):match("%d+%.%d+%.%d+")
	if not luneVersion then
		stdio.ewrite(`{ERROR_PREFIX} Failed to parse lune version\n`)
		return process.exit(1)
	end
end

-- Setup typedefs

local response = net.request(DOWNLOAD_LUNE_SOURCE_URL_FORMAT:format(luneVersion))
if not response.ok then
	stdio.ewrite(`{ERROR_PREFIX} Failed to download Lune source: {response.body}\n`)
	return process.exit(1)
end

local zipFileContents = response.body
local reader = unzip.load(buffer.fromstring(zipFileContents))
local firstEntry = reader:findEntry("/")
if not firstEntry then
	stdio.ewrite(`{ERROR_PREFIX} Failed to find root directory in downloaded lune source code\n`)
	return process.exit(1)
end
local firstChild = firstEntry.children[1]
local typedefs = firstChild.name .. "types"
if not reader:findEntry(typedefs) then
	stdio.ewrite(`{ERROR_PREFIX} Failed to find typedefs directory in downloaded lune source code\n`)
	return process.exit(1)
end

local function getHomeDir(): string
	local home = process.env.HOME
	if home then
		return home
	end
	local homeDir = dirs.homeDir()
	if homeDir then
		return homeDir:toString()
	end

	stdio.ewrite(`{ERROR_PREFIX} Failed to get home directory\n`)
	process.exit(1)
	error("unreachable")
end

local typedefsPath = pathfs.Path.from(TYPEDEFS_PATH_FORMAT:format(getHomeDir(), luneVersion))
if not fs.isDir(typedefsPath) then
	fs.writeDir(typedefsPath)
end

for _, entry in reader:listDirectory(typedefs) do
	local content = reader:extract(entry, {
		isText = true
	})
	local stem = pathfs.Path.from(entry.name):fileStem()
	if not stem then
		stdio.ewrite(`{ERROR_PREFIX} Failed to get file stem of path: {entry.name}\n`)
		process.exit(1)
		error("unreachable")
	end
	fs.writeFile(typedefsPath:join(stem), content)
end

-- Setup .luaurc

local luaurcLuneTypedefs = TYPEDEFS_PATH_FORMAT:format("~", luneVersion)

if not fs.isFile(".luaurc") then
	fs.writeFile(".luaurc", DEFAULT_LUAURC_CONTENTS:format(luaurcLuneTypedefs))
end

local luaurc: {
	aliases: { [string]: string }?,
} = serde.decode("json", fs.readFile(".luaurc"))

if not luaurc.aliases then
	luaurc.aliases = {}
end
(luaurc.aliases :: any).lune = luaurcLuneTypedefs

fs.writeFile(".luaurc", serde.encode("json", luaurc, true))

print("Lune has now been set up and editor type definitions have been generated.")
