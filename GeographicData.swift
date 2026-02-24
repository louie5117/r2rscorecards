//
//  GeographicData.swift
//  r2rscorecards
//
//  Standardized geographic data for user demographics
//

import Foundation

struct GeographicData {
    
    // MARK: - Country Data
    
    struct Country: Identifiable, Hashable {
        let id: String  // ISO code
        let name: String
        let hasStates: Bool
        
        var displayName: String {
            name
        }
    }
    
    struct StateProvince: Identifiable, Hashable {
        let id: String  // State code
        let name: String
        let countryCode: String
    }
    
    // MARK: - Countries List
    
    static let countries: [Country] = {
        var result: [Country] = []
        
        // Get all ISO country codes from iOS
        for code in Locale.isoRegionCodes {
            if let name = Locale.current.localizedString(forRegionCode: code) {
                let hasStates = countriesWithStates.contains(code)
                result.append(Country(id: code, name: name, hasStates: hasStates))
            }
        }
        
        return result.sorted { $0.name < $1.name }
    }()
    
    // Countries that have state/province subdivisions
    private static let countriesWithStates: Set<String> = [
        "US",  // United States
        "CA",  // Canada
        "AU",  // Australia
        "GB",  // United Kingdom
        "DE",  // Germany
        "IN",  // India
        "BR",  // Brazil
        "MX",  // Mexico
    ]
    
    // MARK: - States/Provinces by Country
    
    static func states(for countryCode: String) -> [StateProvince] {
        switch countryCode {
        case "US":
            return usStates
        case "CA":
            return canadianProvinces
        case "AU":
            return australianStates
        case "GB":
            return ukRegions
        case "DE":
            return germanStates
        case "IN":
            return indianStates
        case "BR":
            return brazilianStates
        case "MX":
            return mexicanStates
        default:
            return []
        }
    }
    
    // MARK: - United States
    
    private static let usStates: [StateProvince] = [
        StateProvince(id: "AL", name: "Alabama", countryCode: "US"),
        StateProvince(id: "AK", name: "Alaska", countryCode: "US"),
        StateProvince(id: "AZ", name: "Arizona", countryCode: "US"),
        StateProvince(id: "AR", name: "Arkansas", countryCode: "US"),
        StateProvince(id: "CA", name: "California", countryCode: "US"),
        StateProvince(id: "CO", name: "Colorado", countryCode: "US"),
        StateProvince(id: "CT", name: "Connecticut", countryCode: "US"),
        StateProvince(id: "DE", name: "Delaware", countryCode: "US"),
        StateProvince(id: "FL", name: "Florida", countryCode: "US"),
        StateProvince(id: "GA", name: "Georgia", countryCode: "US"),
        StateProvince(id: "HI", name: "Hawaii", countryCode: "US"),
        StateProvince(id: "ID", name: "Idaho", countryCode: "US"),
        StateProvince(id: "IL", name: "Illinois", countryCode: "US"),
        StateProvince(id: "IN", name: "Indiana", countryCode: "US"),
        StateProvince(id: "IA", name: "Iowa", countryCode: "US"),
        StateProvince(id: "KS", name: "Kansas", countryCode: "US"),
        StateProvince(id: "KY", name: "Kentucky", countryCode: "US"),
        StateProvince(id: "LA", name: "Louisiana", countryCode: "US"),
        StateProvince(id: "ME", name: "Maine", countryCode: "US"),
        StateProvince(id: "MD", name: "Maryland", countryCode: "US"),
        StateProvince(id: "MA", name: "Massachusetts", countryCode: "US"),
        StateProvince(id: "MI", name: "Michigan", countryCode: "US"),
        StateProvince(id: "MN", name: "Minnesota", countryCode: "US"),
        StateProvince(id: "MS", name: "Mississippi", countryCode: "US"),
        StateProvince(id: "MO", name: "Missouri", countryCode: "US"),
        StateProvince(id: "MT", name: "Montana", countryCode: "US"),
        StateProvince(id: "NE", name: "Nebraska", countryCode: "US"),
        StateProvince(id: "NV", name: "Nevada", countryCode: "US"),
        StateProvince(id: "NH", name: "New Hampshire", countryCode: "US"),
        StateProvince(id: "NJ", name: "New Jersey", countryCode: "US"),
        StateProvince(id: "NM", name: "New Mexico", countryCode: "US"),
        StateProvince(id: "NY", name: "New York", countryCode: "US"),
        StateProvince(id: "NC", name: "North Carolina", countryCode: "US"),
        StateProvince(id: "ND", name: "North Dakota", countryCode: "US"),
        StateProvince(id: "OH", name: "Ohio", countryCode: "US"),
        StateProvince(id: "OK", name: "Oklahoma", countryCode: "US"),
        StateProvince(id: "OR", name: "Oregon", countryCode: "US"),
        StateProvince(id: "PA", name: "Pennsylvania", countryCode: "US"),
        StateProvince(id: "RI", name: "Rhode Island", countryCode: "US"),
        StateProvince(id: "SC", name: "South Carolina", countryCode: "US"),
        StateProvince(id: "SD", name: "South Dakota", countryCode: "US"),
        StateProvince(id: "TN", name: "Tennessee", countryCode: "US"),
        StateProvince(id: "TX", name: "Texas", countryCode: "US"),
        StateProvince(id: "UT", name: "Utah", countryCode: "US"),
        StateProvince(id: "VT", name: "Vermont", countryCode: "US"),
        StateProvince(id: "VA", name: "Virginia", countryCode: "US"),
        StateProvince(id: "WA", name: "Washington", countryCode: "US"),
        StateProvince(id: "WV", name: "West Virginia", countryCode: "US"),
        StateProvince(id: "WI", name: "Wisconsin", countryCode: "US"),
        StateProvince(id: "WY", name: "Wyoming", countryCode: "US"),
        StateProvince(id: "DC", name: "Washington D.C.", countryCode: "US"),
    ]
    
    // MARK: - Canada
    
    private static let canadianProvinces: [StateProvince] = [
        StateProvince(id: "AB", name: "Alberta", countryCode: "CA"),
        StateProvince(id: "BC", name: "British Columbia", countryCode: "CA"),
        StateProvince(id: "MB", name: "Manitoba", countryCode: "CA"),
        StateProvince(id: "NB", name: "New Brunswick", countryCode: "CA"),
        StateProvince(id: "NL", name: "Newfoundland and Labrador", countryCode: "CA"),
        StateProvince(id: "NT", name: "Northwest Territories", countryCode: "CA"),
        StateProvince(id: "NS", name: "Nova Scotia", countryCode: "CA"),
        StateProvince(id: "NU", name: "Nunavut", countryCode: "CA"),
        StateProvince(id: "ON", name: "Ontario", countryCode: "CA"),
        StateProvince(id: "PE", name: "Prince Edward Island", countryCode: "CA"),
        StateProvince(id: "QC", name: "Quebec", countryCode: "CA"),
        StateProvince(id: "SK", name: "Saskatchewan", countryCode: "CA"),
        StateProvince(id: "YT", name: "Yukon", countryCode: "CA"),
    ]
    
    // MARK: - Australia
    
    private static let australianStates: [StateProvince] = [
        StateProvince(id: "NSW", name: "New South Wales", countryCode: "AU"),
        StateProvince(id: "QLD", name: "Queensland", countryCode: "AU"),
        StateProvince(id: "SA", name: "South Australia", countryCode: "AU"),
        StateProvince(id: "TAS", name: "Tasmania", countryCode: "AU"),
        StateProvince(id: "VIC", name: "Victoria", countryCode: "AU"),
        StateProvince(id: "WA", name: "Western Australia", countryCode: "AU"),
        StateProvince(id: "ACT", name: "Australian Capital Territory", countryCode: "AU"),
        StateProvince(id: "NT", name: "Northern Territory", countryCode: "AU"),
    ]
    
    // MARK: - United Kingdom
    
    private static let ukRegions: [StateProvince] = [
        StateProvince(id: "ENG", name: "England", countryCode: "GB"),
        StateProvince(id: "SCT", name: "Scotland", countryCode: "GB"),
        StateProvince(id: "WLS", name: "Wales", countryCode: "GB"),
        StateProvince(id: "NIR", name: "Northern Ireland", countryCode: "GB"),
    ]
    
    // MARK: - Germany
    
    private static let germanStates: [StateProvince] = [
        StateProvince(id: "BW", name: "Baden-Württemberg", countryCode: "DE"),
        StateProvince(id: "BY", name: "Bavaria", countryCode: "DE"),
        StateProvince(id: "BE", name: "Berlin", countryCode: "DE"),
        StateProvince(id: "BB", name: "Brandenburg", countryCode: "DE"),
        StateProvince(id: "HB", name: "Bremen", countryCode: "DE"),
        StateProvince(id: "HH", name: "Hamburg", countryCode: "DE"),
        StateProvince(id: "HE", name: "Hesse", countryCode: "DE"),
        StateProvince(id: "MV", name: "Mecklenburg-Vorpommern", countryCode: "DE"),
        StateProvince(id: "NI", name: "Lower Saxony", countryCode: "DE"),
        StateProvince(id: "NW", name: "North Rhine-Westphalia", countryCode: "DE"),
        StateProvince(id: "RP", name: "Rhineland-Palatinate", countryCode: "DE"),
        StateProvince(id: "SL", name: "Saarland", countryCode: "DE"),
        StateProvince(id: "SN", name: "Saxony", countryCode: "DE"),
        StateProvince(id: "ST", name: "Saxony-Anhalt", countryCode: "DE"),
        StateProvince(id: "SH", name: "Schleswig-Holstein", countryCode: "DE"),
        StateProvince(id: "TH", name: "Thuringia", countryCode: "DE"),
    ]
    
    // MARK: - India (Major States)
    
    private static let indianStates: [StateProvince] = [
        StateProvince(id: "AP", name: "Andhra Pradesh", countryCode: "IN"),
        StateProvince(id: "AR", name: "Arunachal Pradesh", countryCode: "IN"),
        StateProvince(id: "AS", name: "Assam", countryCode: "IN"),
        StateProvince(id: "BR", name: "Bihar", countryCode: "IN"),
        StateProvince(id: "CG", name: "Chhattisgarh", countryCode: "IN"),
        StateProvince(id: "GA", name: "Goa", countryCode: "IN"),
        StateProvince(id: "GJ", name: "Gujarat", countryCode: "IN"),
        StateProvince(id: "HR", name: "Haryana", countryCode: "IN"),
        StateProvince(id: "HP", name: "Himachal Pradesh", countryCode: "IN"),
        StateProvince(id: "JK", name: "Jammu and Kashmir", countryCode: "IN"),
        StateProvince(id: "JH", name: "Jharkhand", countryCode: "IN"),
        StateProvince(id: "KA", name: "Karnataka", countryCode: "IN"),
        StateProvince(id: "KL", name: "Kerala", countryCode: "IN"),
        StateProvince(id: "MP", name: "Madhya Pradesh", countryCode: "IN"),
        StateProvince(id: "MH", name: "Maharashtra", countryCode: "IN"),
        StateProvince(id: "MN", name: "Manipur", countryCode: "IN"),
        StateProvince(id: "ML", name: "Meghalaya", countryCode: "IN"),
        StateProvince(id: "MZ", name: "Mizoram", countryCode: "IN"),
        StateProvince(id: "NL", name: "Nagaland", countryCode: "IN"),
        StateProvince(id: "OR", name: "Odisha", countryCode: "IN"),
        StateProvince(id: "PB", name: "Punjab", countryCode: "IN"),
        StateProvince(id: "RJ", name: "Rajasthan", countryCode: "IN"),
        StateProvince(id: "SK", name: "Sikkim", countryCode: "IN"),
        StateProvince(id: "TN", name: "Tamil Nadu", countryCode: "IN"),
        StateProvince(id: "TG", name: "Telangana", countryCode: "IN"),
        StateProvince(id: "TR", name: "Tripura", countryCode: "IN"),
        StateProvince(id: "UP", name: "Uttar Pradesh", countryCode: "IN"),
        StateProvince(id: "UT", name: "Uttarakhand", countryCode: "IN"),
        StateProvince(id: "WB", name: "West Bengal", countryCode: "IN"),
        StateProvince(id: "DL", name: "Delhi", countryCode: "IN"),
    ]
    
    // MARK: - Brazil (Major States)
    
    private static let brazilianStates: [StateProvince] = [
        StateProvince(id: "AC", name: "Acre", countryCode: "BR"),
        StateProvince(id: "AL", name: "Alagoas", countryCode: "BR"),
        StateProvince(id: "AP", name: "Amapá", countryCode: "BR"),
        StateProvince(id: "AM", name: "Amazonas", countryCode: "BR"),
        StateProvince(id: "BA", name: "Bahia", countryCode: "BR"),
        StateProvince(id: "CE", name: "Ceará", countryCode: "BR"),
        StateProvince(id: "DF", name: "Distrito Federal", countryCode: "BR"),
        StateProvince(id: "ES", name: "Espírito Santo", countryCode: "BR"),
        StateProvince(id: "GO", name: "Goiás", countryCode: "BR"),
        StateProvince(id: "MA", name: "Maranhão", countryCode: "BR"),
        StateProvince(id: "MT", name: "Mato Grosso", countryCode: "BR"),
        StateProvince(id: "MS", name: "Mato Grosso do Sul", countryCode: "BR"),
        StateProvince(id: "MG", name: "Minas Gerais", countryCode: "BR"),
        StateProvince(id: "PA", name: "Pará", countryCode: "BR"),
        StateProvince(id: "PB", name: "Paraíba", countryCode: "BR"),
        StateProvince(id: "PR", name: "Paraná", countryCode: "BR"),
        StateProvince(id: "PE", name: "Pernambuco", countryCode: "BR"),
        StateProvince(id: "PI", name: "Piauí", countryCode: "BR"),
        StateProvince(id: "RJ", name: "Rio de Janeiro", countryCode: "BR"),
        StateProvince(id: "RN", name: "Rio Grande do Norte", countryCode: "BR"),
        StateProvince(id: "RS", name: "Rio Grande do Sul", countryCode: "BR"),
        StateProvince(id: "RO", name: "Rondônia", countryCode: "BR"),
        StateProvince(id: "RR", name: "Roraima", countryCode: "BR"),
        StateProvince(id: "SC", name: "Santa Catarina", countryCode: "BR"),
        StateProvince(id: "SP", name: "São Paulo", countryCode: "BR"),
        StateProvince(id: "SE", name: "Sergipe", countryCode: "BR"),
        StateProvince(id: "TO", name: "Tocantins", countryCode: "BR"),
    ]
    
    // MARK: - Mexico
    
    private static let mexicanStates: [StateProvince] = [
        StateProvince(id: "AGU", name: "Aguascalientes", countryCode: "MX"),
        StateProvince(id: "BCN", name: "Baja California", countryCode: "MX"),
        StateProvince(id: "BCS", name: "Baja California Sur", countryCode: "MX"),
        StateProvince(id: "CAM", name: "Campeche", countryCode: "MX"),
        StateProvince(id: "CHP", name: "Chiapas", countryCode: "MX"),
        StateProvince(id: "CHH", name: "Chihuahua", countryCode: "MX"),
        StateProvince(id: "COA", name: "Coahuila", countryCode: "MX"),
        StateProvince(id: "COL", name: "Colima", countryCode: "MX"),
        StateProvince(id: "DUR", name: "Durango", countryCode: "MX"),
        StateProvince(id: "GUA", name: "Guanajuato", countryCode: "MX"),
        StateProvince(id: "GRO", name: "Guerrero", countryCode: "MX"),
        StateProvince(id: "HID", name: "Hidalgo", countryCode: "MX"),
        StateProvince(id: "JAL", name: "Jalisco", countryCode: "MX"),
        StateProvince(id: "MEX", name: "México", countryCode: "MX"),
        StateProvince(id: "MIC", name: "Michoacán", countryCode: "MX"),
        StateProvince(id: "MOR", name: "Morelos", countryCode: "MX"),
        StateProvince(id: "NAY", name: "Nayarit", countryCode: "MX"),
        StateProvince(id: "NLE", name: "Nuevo León", countryCode: "MX"),
        StateProvince(id: "OAX", name: "Oaxaca", countryCode: "MX"),
        StateProvince(id: "PUE", name: "Puebla", countryCode: "MX"),
        StateProvince(id: "QUE", name: "Querétaro", countryCode: "MX"),
        StateProvince(id: "ROO", name: "Quintana Roo", countryCode: "MX"),
        StateProvince(id: "SLP", name: "San Luis Potosí", countryCode: "MX"),
        StateProvince(id: "SIN", name: "Sinaloa", countryCode: "MX"),
        StateProvince(id: "SON", name: "Sonora", countryCode: "MX"),
        StateProvince(id: "TAB", name: "Tabasco", countryCode: "MX"),
        StateProvince(id: "TAM", name: "Tamaulipas", countryCode: "MX"),
        StateProvince(id: "TLA", name: "Tlaxcala", countryCode: "MX"),
        StateProvince(id: "VER", name: "Veracruz", countryCode: "MX"),
        StateProvince(id: "YUC", name: "Yucatán", countryCode: "MX"),
        StateProvince(id: "ZAC", name: "Zacatecas", countryCode: "MX"),
        StateProvince(id: "CMX", name: "Mexico City", countryCode: "MX"),
    ]
    
    // MARK: - Helper Methods
    
    /// Parse a stored region string (e.g., "US-CA" or "GB")
    static func parseRegion(_ regionString: String) -> (country: Country?, state: StateProvince?) {
        let components = regionString.split(separator: "-").map(String.init)
        
        guard let countryCode = components.first,
              let country = countries.first(where: { $0.id == countryCode }) else {
            return (nil, nil)
        }
        
        if components.count == 2 {
            let stateCode = components[1]
            let state = states(for: countryCode).first(where: { $0.id == stateCode })
            return (country, state)
        }
        
        return (country, nil)
    }
    
    /// Format a region for display (e.g., "California, United States" or "United Kingdom")
    static func displayString(for regionString: String) -> String {
        let parsed = parseRegion(regionString)
        
        if let state = parsed.state, let country = parsed.country {
            return "\(state.name), \(country.name)"
        } else if let country = parsed.country {
            return country.name
        } else {
            return regionString // Fallback to raw string
        }
    }
    
    /// Create a region string from country and optional state
    static func regionString(country: Country, state: StateProvince?) -> String {
        if let state = state {
            return "\(country.id)-\(state.id)"
        } else {
            return country.id
        }
    }
}
