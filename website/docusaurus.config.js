const themes = require("prism-react-renderer").themes;

// @ts-check

const config = {
	title: "Roblox Utils",
	tagline: "A collection of Luau utilities for Roblox",
	url: "https://Echo-Innovations.github.io",
	baseUrl: "/Roblox-Utils/",
	organizationName: "Echo-Innovations",
	projectName: "Roblox-Utils",
	onBrokenLinks: "throw",
	onBrokenMarkdownLinks: "warn",
	themeConfig: {
		colorMode: {
			defaultMode: "dark",
			disableSwitch: false,
		},
		navbar: {
			items: [
				{ to: "/", label: "Home", position: "left" },
				{ type: "doc", docId: "introduction", label: "Docs", position: "left" },
			],
		},
		prism: {
			additionalLanguages: ["lua"],
			theme: themes.dracula,
			defaultLight: themes.github,
		},
	},
	presets: [
		[
			"classic",
			{
				docs: {
					path: "../docs",
					sidebarPath: require.resolve("./sidebars.js"),
				},
				theme: {
					customCss: require.resolve("./src/css/custom.css"),
				},
			},
		],
	],
};

module.exports = config;