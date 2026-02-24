//
//  GeographicPicker.swift
//  r2rscorecards
//
//  Geographic location picker with country and state/province selection
//

import SwiftUI

struct GeographicPicker: View {
    @Binding var regionString: String
    @State private var selectedCountry: GeographicData.Country?
    @State private var selectedState: GeographicData.StateProvince?
    @State private var showingCountryPicker = false
    @State private var showingStatePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Country Selection
            VStack(alignment: .leading, spacing: 4) {
                Text("Country")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button(action: { showingCountryPicker = true }) {
                    HStack {
                        Text(selectedCountry?.name ?? "Select Country")
                            .foregroundStyle(selectedCountry == nil ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            // State/Province Selection (if applicable)
            if let country = selectedCountry, country.hasStates {
                VStack(alignment: .leading, spacing: 4) {
                    Text("State/Province")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button(action: { showingStatePicker = true }) {
                        HStack {
                            Text(selectedState?.name ?? "Select State/Province")
                                .foregroundStyle(selectedState == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Display current selection
            if selectedCountry != nil {
                Text(GeographicData.displayString(for: regionString))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .onAppear {
            loadCurrentSelection()
        }
        .sheet(isPresented: $showingCountryPicker) {
            CountryPickerView(selectedCountry: $selectedCountry) {
                updateRegionString()
                // Clear state when country changes
                selectedState = nil
            }
        }
        .sheet(isPresented: $showingStatePicker) {
            if let country = selectedCountry {
                StatePickerView(country: country, selectedState: $selectedState) {
                    updateRegionString()
                }
            }
        }
    }
    
    private func loadCurrentSelection() {
        let parsed = GeographicData.parseRegion(regionString)
        selectedCountry = parsed.country
        selectedState = parsed.state
    }
    
    private func updateRegionString() {
        if let country = selectedCountry {
            regionString = GeographicData.regionString(country: country, state: selectedState)
        } else {
            regionString = ""
        }
    }
}

// MARK: - Country Picker

private struct CountryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCountry: GeographicData.Country?
    var onSelect: () -> Void
    
    @State private var searchText = ""
    
    private var filteredCountries: [GeographicData.Country] {
        if searchText.isEmpty {
            return GeographicData.countries
        } else {
            return GeographicData.countries.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredCountries) { country in
                Button(action: {
                    selectedCountry = country
                    onSelect()
                    dismiss()
                }) {
                    HStack {
                        Text(country.name)
                        Spacer()
                        if selectedCountry?.id == country.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search countries")
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - State Picker

private struct StatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let country: GeographicData.Country
    @Binding var selectedState: GeographicData.StateProvince?
    var onSelect: () -> Void
    
    @State private var searchText = ""
    
    private var states: [GeographicData.StateProvince] {
        GeographicData.states(for: country.id)
    }
    
    private var filteredStates: [GeographicData.StateProvince] {
        if searchText.isEmpty {
            return states
        } else {
            return states.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredStates) { state in
                Button(action: {
                    selectedState = state
                    onSelect()
                    dismiss()
                }) {
                    HStack {
                        Text(state.name)
                        Spacer()
                        if selectedState?.id == state.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Search states/provinces")
            .navigationTitle("Select State/Province")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Previews

struct GeographicPicker_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Preview1()
            Preview2()
        }
    }
    
    struct Preview1: View {
        @State private var region = ""
        
        var body: some View {
            Form {
                Section("Location") {
                    GeographicPicker(regionString: $region)
                }
                
                Section("Selected") {
                    Text("Region: \(region)")
                    Text("Display: \(GeographicData.displayString(for: region))")
                }
            }
        }
    }
    
    struct Preview2: View {
        @State private var region = "US-CA"
        
        var body: some View {
            Form {
                Section("Location") {
                    GeographicPicker(regionString: $region)
                }
                
                Section("Selected") {
                    Text("Region: \(region)")
                    Text("Display: \(GeographicData.displayString(for: region))")
                }
            }
        }
    }
}
