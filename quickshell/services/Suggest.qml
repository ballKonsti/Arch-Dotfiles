pragma Singleton

import Quickshell
import QtQuick

// Film and series suggestions for the Cadence launcher, from JustWatch's
// public GraphQL API (no key). One request fetches every row; each title
// comes with a poster, a backdrop, and a deep link to where it streams.
//
// Only titles included with a subscription (or free) on the services
// Cadence knows are suggested, so Enter can always play them.
Singleton {
    id: root

    readonly property string country: "AT"
    readonly property string language: "de"
    // JustWatch package short names: Netflix, Prime Video, Disney+, Max, Crunchyroll.
    readonly property var packages: ["nfx", "amp", "dnp", "mxx", "cru"]

    readonly property var rowSpecs: [
        { key: "trending", label: "Trending now",          sort: "TRENDING", types: ["MOVIE", "SHOW"], packages: root.packages },
        { key: "movies",   label: "Popular movies",        sort: "POPULAR",  types: ["MOVIE"],         packages: root.packages },
        { key: "shows",    label: "Popular series",        sort: "POPULAR",  types: ["SHOW"],          packages: root.packages },
        { key: "netflix",  label: "Top on Netflix",        sort: "POPULAR",  types: ["MOVIE", "SHOW"], packages: ["nfx"] },
        { key: "prime",    label: "Top on Prime Video",    sort: "POPULAR",  types: ["MOVIE", "SHOW"], packages: ["amp"] },
        { key: "disney",   label: "Top on Disney+",        sort: "POPULAR",  types: ["MOVIE", "SHOW"], packages: ["dnp"] },
        { key: "max",      label: "Top on Max",            sort: "POPULAR",  types: ["MOVIE", "SHOW"], packages: ["mxx"] },
        { key: "anime",    label: "Anime on Crunchyroll",  sort: "POPULAR",  types: ["SHOW"],          packages: ["cru"] }
    ]

    // [{ label, items: [title…] }], in rowSpecs order, empty rows dropped.
    property var rows: []
    property bool loading: false
    property string error: ""
    property real fetchedAt: 0

    // JustWatch package → the Cadence app that plays it.
    readonly property var appFor: ({
            "netflix": "Netflix",
            "netflixkids": "Netflix",
            "amazonprime": "Prime Video",
            "disneyplus": "Disney+",
            "max": "Max",
            "crunchyroll": "Crunchyroll",
            "plex": "Plex"
        })

    readonly property var genreNames: ({
            act: "Action", ani: "Animation", cmy: "Comedy", crm: "Crime", doc: "Documentary",
            drm: "Drama", fml: "Family", fnt: "Fantasy", hst: "History", hrr: "Horror",
            msc: "Music", rma: "Romance", scf: "Sci-Fi", spt: "Sport", trl: "Thriller",
            war: "War", wsn: "Western", rly: "Reality", eur: "European"
        })

    function image(path: string, profile: string): string {
        return path ? "https://images.justwatch.com" + path.replace("{profile}", profile).replace("{format}", "jpg") : "";
    }

    // Refetch when the data is missing or older than three hours.
    function refreshIfStale(): void {
        if (!root.loading && (root.rows.length === 0 || Date.now() - root.fetchedAt > 3 * 3600 * 1000))
            root.refresh();
    }

    function refresh(): void {
        root.loading = true;
        root.error = "";

        const fields = `id objectType
            content(country: $c, language: $l) {
                title originalReleaseYear posterUrl shortDescription runtime ageCertification
                backdrops { backdropUrl }
                genres { shortName }
                scoring { imdbScore }
            }
            offers(country: $c, platform: WEB) {
                monetizationType standardWebURL
                package { clearName technicalName }
            }`;
        const parts = root.rowSpecs.map(r => `${r.key}: popularTitles(country: $c, first: 24, sortBy: ${r.sort}, filter: {
                objectTypes: [${r.types.join(", ")}],
                packages: [${r.packages.map(p => `"${p}"`).join(", ")}],
                monetizationTypes: [FLATRATE, FREE, ADS]
            }) { edges { node { ${fields} } } }`);
        const query = `query($c: Country!, $l: Language!) { ${parts.join("\n")} }`;

        const xhr = new XMLHttpRequest();
        xhr.open("POST", "https://apis.justwatch.com/graphql");
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            root.loading = false;
            if (xhr.status !== 200) {
                root.error = `Couldn't load suggestions (HTTP ${xhr.status || "offline"})`;
                return;
            }
            try {
                const data = JSON.parse(xhr.responseText).data;
                root.rows = root.rowSpecs.map(r => ({
                            label: r.label,
                            items: (data[r.key]?.edges ?? []).map(e => root.toTitle(e.node)).filter(t => t !== null)
                        })).filter(r => r.items.length > 0);
                root.fetchedAt = Date.now();
            } catch (e) {
                root.error = "Couldn't read suggestions";
            }
        };
        xhr.send(JSON.stringify({
            query: query,
            variables: {
                c: root.country,
                l: root.language
            }
        }));
    }

    function toTitle(node: var): var {
        const c = node.content;
        if (!c)
            return null;

        // Where to play it: the first included-with-subscription (or free)
        // offer on a service Cadence has an app for.
        let offer = null;
        for (const o of node.offers ?? []) {
            const app = root.appFor[o.package.technicalName];
            if (app && ["FLATRATE", "FREE", "ADS"].includes(o.monetizationType)) {
                offer = {
                    app: app,
                    service: o.package.clearName,
                    url: o.standardWebURL
                };
                break;
            }
        }
        if (!offer)
            return null;

        const backdrop = c.backdrops?.[0]?.backdropUrl ?? "";
        return {
            id: node.id,
            kind: node.objectType === "SHOW" ? "Series" : "Movie",
            title: c.title,
            year: c.originalReleaseYear ?? 0,
            blurb: c.shortDescription ?? "",
            runtime: c.runtime ?? 0,
            age: c.ageCertification ?? "",
            imdb: c.scoring?.imdbScore ?? 0,
            genres: (c.genres ?? []).map(g => root.genreNames[g.shortName]).filter(g => g).slice(0, 3),
            poster: root.image(c.posterUrl, "s332"),
            card: root.image(backdrop, "s640") || root.image(c.posterUrl, "s332"),
            backdrop: root.image(backdrop, "s1440"),
            offer: offer
        };
    }
}
