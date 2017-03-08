import PackageDescription

let package = Package(
	name: "Reswifq",
	targets: [
		Target(name: "Reswifq"),
		Target(name: "Reswifc", dependencies: ["Reswifq"])
	],
	dependencies: [
		.Package(url: "https://github.com/reswifq/pool.git", majorVersion: 1)
	]
)
