import PackageDescription

let package = Package(
	name: "Reswifq",
	targets: [
		Target(name: "Reswifq")
	],
	dependencies: [
		.Package(url: "https://github.com/reswifq/pool.git", majorVersion: 1)
	]
)
