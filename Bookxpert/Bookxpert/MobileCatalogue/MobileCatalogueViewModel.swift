import Foundation
import Combine
import UserNotifications

@MainActor
protocol MobileCatalogueViewModelDelegate: AnyObject {
    func didSelectEditItem(_ item: MobileCatalogueItem)
    func didSelectSideMenu()
}

@MainActor
enum MobileCatalogueViewState {
    case loading(message: String)
    case loaded(list: [MobileCatalogueItem])
    case error(title: String, message: String)
}

@MainActor
protocol MobileCatalogueViewModelProtocol: ObservableObject {
    var viewState: MobileCatalogueViewState { get }
    var title: String { get }
    var errorMessage: String? { get }
    
    func fetchCatalogue(forceUpdate: Bool) async
    func deleteItem(_ item: MobileCatalogueItem)
    func editItem(_ item: MobileCatalogueItem)
    func showSideMenu()
}

extension MobileCatalogueViewModelProtocol {
    func fetchCatalogue() async {
        await fetchCatalogue(forceUpdate: false)
    }
}

@MainActor
final class MobileCatalogueViewModel: MobileCatalogueViewModelProtocol {
    @Published var items: [MobileCatalogueItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var viewState: MobileCatalogueViewState = .loading(message: "Fetching Catalogue...")
    @Published var notificationsEnabled: Bool = true

    private let repository: MobileCatalogueRepositing
    private weak var delegate: MobileCatalogueViewModelDelegate?
    private var cancellables = Set<AnyCancellable>()

    init(repository: MobileCatalogueRepositing, delegate: MobileCatalogueViewModelDelegate? = nil) {
        self.repository = repository
        self.delegate = delegate
        subscribeToCatalogue()
        requestNotificationPermission()
    }
    
    private func subscribeToCatalogue() {
        repository.catalogueItemsPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] list in
                let sortedList = list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                self?.viewState = .loaded(list: sortedList)
            })
            .store(in: &cancellables)
    }
    
    var title: String { "Phones" }
    
    func fetchCatalogue(forceUpdate: Bool)async {
        do {
            try await repository.fetchCatalogue(forceUpdate: forceUpdate)
        } catch {
            viewState = .error(title: "Unable to fetch catalogue", message:  error.localizedDescription)
        }
    }
    
    func deleteItem(_ item: MobileCatalogueItem) {
        do {
            try repository.deleteCatalogueItem(item)
            if notificationsEnabled {
                sendDeletionNotification(for: item)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func editItem(_ item: MobileCatalogueItem) {
        delegate?.didSelectEditItem(item)
    }
    
    func showSideMenu() {
        delegate?.didSelectSideMenu()
    }

    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Task { @MainActor in
                self.notificationsEnabled = granted
            }
        }
    }

    private func sendDeletionNotification(for item: MobileCatalogueItem) {
        let content = UNMutableNotificationContent()
        content.title = "Item Deleted"
        content.body = "You deleted: \(item.name)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

}

   
