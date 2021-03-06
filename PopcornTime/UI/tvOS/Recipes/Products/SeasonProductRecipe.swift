

import TVMLKitchen
import PopcornKit
import ObjectMapper

public class SeasonProductRecipe: NSObject, RecipeType, UINavigationControllerDelegate {

    let show: Show
    var season: Int

    public let theme = DefaultTheme()
    public let presentationType = PresentationType.default

    public init(show: Show, currentSeason: Int? = nil) {
        self.show = show
        self.season = currentSeason ?? show.seasonNumbers.last ?? -1
        super.init()
        Kitchen.appController.navigationController.delegate = self
    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ActionHandler.shared.replaceTitle(self.show.title, withUrlString: self.fanartLogoString, belongingToViewController: viewController)
        }
    }

    public var xmlString: String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
        xml += "<document>"
        xml += template
        xml += "</document>"
        return xml
    }
    
    var episodeShelf: String {
        var xml = "<header>" + "\n"
        xml += "<title>\(episodeCount)</title>" + "\n"
        xml += "</header>" + "\n"
        xml += "<section>" + "\n"
        xml +=  episodesString + "\n"
        xml += "</section>" + "\n"
        return xml
    }

    var seasonString: String {
        return "Season \(season)"
    }

    var actorsString: String {
        return show.actors.map { "<text>\($0.name)</text>" }.joined(separator: "")
    }

    var genresString: String {
        if let first = show.genres.first {
            var genreString = first
            if show.genres.count > 2 {
                genreString += " & \(show.genres[1])"
            }
            return "\(genreString.capitalized.cleaned)"
        }
        return ""
    }

    var episodeCount: String {
        return "\(show.episodes.filter({$0.season == season}).count) Episodes"
    }

    var castString: String {

        let actors: [String] = show.actors.map {
            var headshot = ""
            if let image = $0.mediumImage {
                headshot = " src=\"\(image)\""
            }
            let name = $0.name.components(separatedBy: " ")
            var string = "<monogramLockup actionID=\"showShowCredits»\($0.name)»\($0.imdbId)\">" + "\n"
            string += "<monogram firstName=\"\(name.first!)\" lastName=\"\(name.last!)\"\(headshot)/>"
            string += "<title>\($0.name.cleaned)</title>" + "\n"
            string += "<subtitle>Actor</subtitle>" + "\n"
            string += "</monogramLockup>" + "\n"
            return string
        }
        
        let cast: [String] = show.crew.map {
            var headshot = ""
            if let image = $0.mediumImage {
                headshot = " src=\"\(image)\""
            }
            let name = $0.name.components(separatedBy: " ")
            var string = "<monogramLockup actionID=\"showMovieCredits»\($0.name)»\($0.imdbId)\">" + "\n"
            string += "<monogram firstName=\"\(name.first!)\" lastName=\"\(name.last!)\"\(headshot)/>"
            string += "<title>\($0.name.cleaned)</title>" + "\n"
            string += "<subtitle>\($0.job.cleaned)</subtitle>" + "\n"
            string += "</monogramLockup>" + "\n"
            return string
        }
        let mapped = actors + cast
        return mapped.joined(separator: "\n")
    }

    var watchlistButton: String {
        var string = "<buttonLockup id =\"watchlistButton\" actionID=\"toggleShowWatchlist»\(Mapper<Show>().toJSONString(show)?.cleaned ?? "")\">\n"
        string += "<badge id =\"watchlistButtonBadge\" src=\"resource://button-{{WATCHLIST_ACTION}}\" />\n"
        string += "<title>Watchlist</title>\n"
        string += "</buttonLockup>"
        return string
    }

    var themeSong: String {
        var s = "<background>\n"
        s += "<audio>\n"
        s += "<asset id=\"tv_theme\" src=\"http://tvthemes.plexapp.com/\(show.tvdbId ?? "").mp3\"/>"
        s += "</audio>\n"
        s += "</background>\n"
        return ""
    }

    var seasonsButtonTitle: String {
        return "<badge src=\"resource://seasons_mask\" width=\"50px\" height=\"37px\"></badge>"
    }
    
    var networkString: String {
        if let network = show.network { return "Watch \(show.title) on \(network)" }
        return ""
    }
    
    var fanartLogoString = ""

    var seasonsButton: String {
        var string = "<buttonLockup actionID=\"showSeasons»\(Mapper<Show>().toJSONString(show)?.cleaned ?? "")»\(Mapper<Episode>().toJSONString(show.episodes)?.cleaned ?? "")\">"
        string += "\(seasonsButtonTitle)"
        string += "<title>Series</title>"
        string += "</buttonLockup>"
        return string
    }

    var episodesString: String {
        let mapped: [String] = show.episodes.filter({$0.season == season}).map {
            var string = "<lockup actionID=\"chooseQuality»\(Mapper<Torrent>().toJSONString($0.torrents)?.cleaned ?? "")»\(Mapper<Episode>().toJSONString($0)?.cleaned ?? "")\">" + "\n"
            string += "<img class=\"placeholder\" src=\"\($0.mediumBackgroundImage ?? "")\" width=\"310\" height=\"175\" />" + "\n"
            string += "<title>\($0.episode). \($0.title.cleaned)</title>" + "\n"
            string += "<overlay class=\"overlayPosition\">" + "\n"
            if WatchedlistManager.episode.isAdded($0.id) {
                string += "<badge src=\"resource://overlay-checkmark\" class=\"whiteButton overlayPosition\"/>" + "\n"
            } else if WatchedlistManager.episode.currentProgress($0.id) > 0.0 {
                string += "<progressBar value=\"\(WatchedlistManager.episode.currentProgress($0.id))\" />" + "\n"
            }
            string += "</overlay>" + "\n"
            string += "<relatedContent>" + "\n"
            string += "<infoTable>" + "\n"
            string +=   "<header>" + "\n"
            string +=       "<title>\($0.title.cleaned)</title>" + "\n"
            string +=   "</header>" + "\n"
            string +=   "<info>" + "\n"
            string +=       "<header>" + "\n"
            string +=           "<title>" + "\n"
            if let date = $0.firstAirDate {
                string +=     "\(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))" + "\n"
            }
            if let genre = $0.show.genres.first {
                string +=     "\(genre.capitalized)" + "\n"
            }
            string +=           "</title>" + "\n"
            string +=       "</header>" + "\n"
            string +=   "<description allowsZooming=\"true\" moreLabel=\"more\" actionID=\"showDescription»\($0.title.cleaned)»\($0.summary.cleaned)\">\($0.summary.cleaned)</description>" + "\n"
            string +=   "</info>" + "\n"
            string += "</infoTable>" + "\n"
            string += "</relatedContent>" + "\n"
            string += "</lockup>" + "\n"
            return string
        }
        return mapped.joined(separator: "\n")
    }
    
    var suggestionsString: String {
        let mapped: [String] = show.related.map {
            var string = "<lockup actionID=\"showShow»\($0.title.cleaned)»\($0.id)\">" + "\n"
            string += "<img class=\"placeholder\" src=\"\($0.smallCoverImage ?? "")\" width=\"150\" height=\"226\" />" + "\n"
            string += "<title class=\"hover\">\($0.title.cleaned)</title>" + "\n"
            string += "</lockup>" + "\n"
            return string
        }
        return mapped.joined(separator: "\n")
    }

    public var template: String {
        var xml = ""
        if let file = Bundle.main.url(forResource: "SeasonProductRecipe", withExtension: "xml") {
            do {
                xml = try String(contentsOf: file)

                xml = xml.replacingOccurrences(of: "{{TITLE}}", with: show.title.cleaned)
                xml = xml.replacingOccurrences(of: "{{SEASON}}", with: seasonString)
                
                xml = xml.replacingOccurrences(of: "{{GENRES}}", with: genresString)
                xml = xml.replacingOccurrences(of: "{{DESCRIPTION}}", with: show.summary.cleaned)
                xml = xml.replacingOccurrences(of: "{{SHORT_DESCRIPTION}}", with: show.summary.cleaned)
                xml = xml.replacingOccurrences(of: "{{IMAGE}}", with: show.largeCoverImage ?? "")
                xml = xml.replacingOccurrences(of: "{{FANART_IMAGE}}", with: show.largeBackgroundImage ?? "")
                xml = xml.replacingOccurrences(of: "{{YEAR}}", with: show.year.cleaned)
                xml = xml.replacingOccurrences(of: "{{RUNTIME}}", with: (show.runtime ?? "0") + " min")
                
                xml = xml.replacingOccurrences(of: "{{NETWORK}}", with: networkString)
                xml = xml.replacingOccurrences(of: "{{NETWORK-FOOTER}}", with: show.network?.cleaned ?? "TV")
                
                xml = xml.replacingOccurrences(of: "{{SUGGESTIONS}}", with: suggestionsString)
                
                xml = xml.replacingOccurrences(of: "{{WATCH_LIST_BUTTON}}", with: watchlistButton)
                if WatchlistManager<Show>.show.isAdded(show) {
                    xml = xml.replacingOccurrences(of: "{{WATCHLIST_ACTION}}", with: "remove")
                } else {
                    xml = xml.replacingOccurrences(of: "{{WATCHLIST_ACTION}}", with: "add")
                }

                xml = xml.replacingOccurrences(of: "{{EPISODE_SHELF}}", with: episodeShelf)

                xml = xml.replacingOccurrences(of: "{{CAST}}", with: castString)

                xml = xml.replacingOccurrences(of: "{{SEASONS_BUTTON}}", with: seasonsButton)
            } catch {
                print("Could not open Catalog template")
            }
        }
        return xml
    }
}
