//
//  AppRouter.swift
//  terrariumidle_ios
//
//  Created by vương quang huy on 4/2/26.
//

import Combine
import Foundation
import SwiftUI

enum AppRoute: Hashable {
    case loginView(id: String)
    case splashView
    case homeView
    case storeView
    case storeItem(itemId: String)
    case accountView
    case eventView
    case discoveryView
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard path.count > 0 else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    func setStack(_ routes: [AppRoute]) {
        var p = NavigationPath()
        for r in routes {
            p.append(r)
        }
        path = p
    }

    func replaceRoot(_ route: AppRoute) {
        var p = NavigationPath()
        p.append(route)
        path = p
    }
}

struct AppRouterView: View {
    @StateObject private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            SplashView(router: router)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .loginView(_):
                        LoginView()
                    case .splashView:
                        EmptyView()
                    case .homeView:
                        HomeView()
                    case .storeView:
                        StoreView()
                    case .storeItem(let itemId):
                        StoreView(initialItemId: itemId)
                    case .accountView:
                        AccountView()
                    case .eventView:
                        EventView()
                    case .discoveryView:
                        DiscoveryView()
                    }
                }
        }
        .environmentObject(router)
    }
}

#Preview {
    AppRouterView()
}
