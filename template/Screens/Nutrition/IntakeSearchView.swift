import SwiftUI

struct IntakeSearchView: View {
    @EnvironmentObject private var environment: HausContainer
    @EnvironmentObject private var network: NetworkMonitor
    @StateObject private var vm = IntakeSearchViewModel()

    var onPick: (FoodProduct) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GridSpacing.md) {
                searchField
                if !vm.localResults.isEmpty {
                    SectionHeader(title: "Saved Foods")
                    ForEach(vm.localResults) { product in localRow(product) }
                }
                SectionHeader(title: "OpenFoodFacts Results")
                remoteContent
            }
            .padding(GridSpacing.md)
        }
        .background(BauhausColors.background)
        .navigationTitle("Search Food")
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.configure(service: environment.openFoodFactsService, repository: environment.foodProductRepository, networkMonitor: network)
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: GridIcons.search).foregroundStyle(BauhausColors.textMuted)
            TextField("Search for oatmeal, banana, rice...", text: $vm.query)
                .foregroundStyle(BauhausColors.textPrimary)
                .submitLabel(.search)
                .onChange(of: vm.query) { _, _ in vm.queryChanged() }
                .onSubmit { Task { await vm.search() } }
        }
        .padding().background(BauhausColors.surface).clipShape(RoundedRectangle(cornerRadius: SharpRadius.md))
    }

    @ViewBuilder
    private var remoteContent: some View {
        switch vm.remoteState {
        case .idle:
            Text("Type at least 2 characters to search.").font(GridTypography.caption).foregroundStyle(BauhausColors.textMuted)
        case .loading:
            LoadingStateView(message: "Searching...")
        case .loaded(let products):
            ForEach(products) { dto in remoteRow(dto) }
        case .empty:
            BlankGridView(systemImage: "magnifyingglass", title: "No products found", message: "Try another search term or create a food manually.")
        case .error(let message):
            ErrorStateView(title: "Search failed", message: message, retryTitle: "Retry") { Task { await vm.search() } }
        case .offline:
            BlankGridView(systemImage: GridIcons.offline, title: "No Internet Connection", message: "You can still use saved foods or create a food manually.")
        }
    }

    private func localRow(_ product: FoodProduct) -> some View {
        Button { onPick(product) } label: {
            GridBlock {
                HStack {
                    VStack(alignment: .leading) {
                        Text(product.name).foregroundStyle(BauhausColors.textPrimary)
                        Text("\(NumberFormatterUtils.int(product.caloriesPer100g)) kcal/100g").font(.caption).foregroundStyle(BauhausColors.textMuted)
                    }
                    Spacer()
                    Image(systemName: "plus.circle.fill").foregroundStyle(BauhausColors.primary)
                }
            }
        }
    }

    private func remoteRow(_ dto: OpenFoodFactsProductDTO) -> some View {
        GridBlock {
            HStack(spacing: GridSpacing.sm) {
                GridImageLoader(urlString: dto.imageUrl, placeholderSymbol: "fork.knife").frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading) {
                    Text(dto.displayName).foregroundStyle(BauhausColors.textPrimary).lineLimit(2)
                    if let brand = dto.brands { Text(brand).font(.caption).foregroundStyle(BauhausColors.textMuted).lineLimit(1) }
                    if !dto.hasCompleteNutrition {
                        Text("Incomplete nutrition data").font(.caption2).foregroundStyle(BauhausColors.warning)
                    }
                }
                Spacer()
                Button {
                    if let product = vm.saveRemoteProduct(dto) { onPick(product) }
                } label: { Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(BauhausColors.primary) }
                .frame(width: 44, height: 44)
            }
        }
    }
}

struct SavedFoodsView: View {
    @EnvironmentObject private var environment: HausContainer
    var onPick: (FoodProduct) -> Void
    @State private var products: [FoodProduct] = []
    @State private var query = ""

    var body: some View {
        Group {
            if products.isEmpty {
                BlankGridView(systemImage: "bookmark", title: "No saved foods", message: "Create a food manually or save one from OpenFoodFacts.")
            } else {
                List {
                    ForEach(products.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }) { product in
                        Button { onPick(product) } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.name).foregroundStyle(BauhausColors.textPrimary)
                                    Text("\(NumberFormatterUtils.int(product.caloriesPer100g)) kcal/100g").font(.caption).foregroundStyle(BauhausColors.textMuted)
                                }
                                Spacer()
                                if product.isFavorite { Image(systemName: "star.fill").foregroundStyle(BauhausColors.warning) }
                            }
                        }
                        .listRowBackground(BauhausColors.surface)
                        .swipeActions {
                            Button(role: .destructive) { try? environment.foodProductRepository.deleteProduct(product); reload() } label: { Label("Delete", systemImage: GridIcons.delete) }
                        }
                    }
                }
                .listStyle(.insetGrouped).scrollContentBackground(.hidden)
            }
        }
        .background(BauhausColors.background)
        .navigationTitle("Saved Foods")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(BauhausColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .searchable(text: $query)
        .onAppear(perform: reload)
    }

    private func reload() { products = (try? environment.foodProductRepository.fetchProducts()) ?? [] }
}
