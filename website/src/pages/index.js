import React from "react";
import Layout from "@theme/Layout";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";

const Features = [
	{
		Title: "Signals",
		Description: "Event objects without the instance overhead. Every signal has a unique Id and lives in a registry.",
	},
	{
		Title: "Reactive state",
		Description: "Observer + Computed: tables that fire signals on writes and values that recompute from dependencies.",
	},
	{
		Title: "Diffing",
		Description: "DeepDiff, DeepEqual and Patch: generate changes, compare state, apply the diff back.",
	},
	{
		Title: "Time",
		Description: "Timestamp formatting, relative time, countdowns and unit converters, all with templates.",
	},
	{
		Title: "Utilities",
		Description: "Tables, strings, math, randomness, colors, functions, timers, reflection helpers.",
	},
	{
		Title: "Typed",
		Description: "Every function is annotated; the module typechecks under --!strict and ships exported types.",
	},
];

export default function Home() {
	const { siteConfig } = useDocusaurusContext();

	return (
		<Layout title={siteConfig.title} description={siteConfig.tagline}>
			<main style={{ maxWidth: "900px", margin: "0 auto", padding: "3rem 1.5rem" }}>
				<section style={{ textAlign: "center" }}>
					<h1 style={{ fontSize: "3rem", marginBottom: "0.5rem" }}>{siteConfig.title}</h1>
					<p style={{ fontSize: "1.25rem", opacity: 0.8 }}>{siteConfig.tagline}</p>
					<div style={{ marginTop: "1.5rem" }}>
						<Link
							className="button button--primary button--lg"
							to="/docs/introduction"
						>
							Get Started
						</Link>
					</div>
				</section>

				<section style={{ marginTop: "3rem" }}>
					<h2 style={{ textAlign: "center" }}>What's inside</h2>
					<div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(260px, 1fr))", gap: "1.5rem" }}>
						{Features.map((Feature) => (
							<div
								key={Feature.Title}
								style={{
									background: "var(--ifm-background-surface-color)",
									border: "1px solid var(--ifm-toc-border-color)",
									borderRadius: "10px",
									padding: "1rem 1.25rem",
									boxShadow: "0 2px 12px var(--ifm-panel-shadow)",
								}}
							>
								<h3 style={{ marginBottom: "0.25rem" }}>{Feature.Title}</h3>
								<p style={{ margin: 0 }}>{Feature.Description}</p>
							</div>
						))}
					</div>
				</section>
			</main>
		</Layout>
	);
}