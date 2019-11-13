//
//  PageViewController.swift
//  Foodist
//
//  Created by Namitha Pavithran on 18/07/2019.
//

import UIKit

let reloadPageNotification: Notification.Name = Notification.Name(rawValue: "reloadPage")

class PageViewController: UIPageViewController {

    var favouriteCategory = "dessert"
    var endPoint = "https://spoonacular-recipe-food-nutrition-v1.p.rapidapi.com/recipes/search?type="
    let numberOfPages = 5
    var recipeList: RecipeList?

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(reloadPage), name: reloadPageNotification, object: nil)
        setUpPageControl()
        loadUrl()
    }

    @objc func reloadPage() {
        print("notification called")
        loadUrl()
    }

    fileprivate func setUpPageControl() {
        let appearance = UIPageControl.appearance(whenContainedInInstancesOf: [UIPageViewController.self])
        appearance.pageIndicatorTintColor = .lightGray
        appearance.currentPageIndicatorTintColor = .black
    }

    func instantiateViewController() -> CategoryViewController {
        guard
            let selectedCategoryVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "selectedcategoryVC") as? CategoryViewController
            else { preconditionFailure("unexpected viewcontroller") }
            return selectedCategoryVC
    }

    fileprivate func setUpInitialPage() {
        let firstViewController = instantiateViewController()
        if let results = recipeList?.results[0] {
            firstViewController.recipe = results
            firstViewController.index = 0
        }
        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: true,
                           completion: nil)
    }

    func formUrl() {

        func fetchPreference () {
            if let savedPreference = UserDefaults.standard.object(forKey: "UserPreference") as? Data {
                let decoder = JSONDecoder()
                do {
                    let savedPreference = try decoder.decode([Preference].self, from: savedPreference)
                    let typePreference = savedPreference.filter { $0.apiCategory == "type" }
                    if typePreference.count > 0 {
                        favouriteCategory = typePreference.first?.options.first?.apiName ?? "dessert"
                    }

                } catch let error {
                    print("error in decoding preference ", error)
                    return
                }
            }
        }
        endPoint += favouriteCategory + "&number=\(numberOfPages)"
    }

    @objc func loadUrl() {
        formUrl()
        let networkHandler = NetworkHandler()
        networkHandler.getAPIData(endPoint) { (result: Result<RecipeList, NetworkError>) in
            if case .failure(let error) = result {
                switch error {
                case .networkError(let message):
                    DispatchQueue.main.async {
                        self.showAlert(message)
                    }
                }
            }
            guard
                case .success(let value) = result
                else { return }
            self.recipeList = value
            if self.recipeList != nil {
                DispatchQueue.main.async {
                    self.setUpInitialPage()
                    self.setUpPageControl()
                }
            }
        }
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}

extension PageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let selectedcategoryViewController = viewController as? CategoryViewController {
            let currentIndex = selectedcategoryViewController.index
            if currentIndex == 0 {
                return nil
            } else {
                let previousViewController = instantiateViewController()
                previousViewController.index = currentIndex - 1
                if let result = recipeList?.results[currentIndex - 1] {
                    previousViewController.recipe = result
                    // previousViewController.setUpViewController()
                }
                return previousViewController
            }
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let selectedcategoryViewController = viewController as? CategoryViewController {
            let currentIndex = selectedcategoryViewController.index
            if let recipeList = recipeList {
                let results = recipeList.results
                if currentIndex == results.count - 1 {
                    return nil
                } else {
                    let nextViewController = instantiateViewController()
                    nextViewController.index = currentIndex + 1
                    nextViewController.recipe = recipeList.results[currentIndex+1]
                    return nextViewController
                }
            }
        }
        return nil
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return numberOfPages
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
