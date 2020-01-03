//
//  NotificationViewController.swift
//  swaap
//
//  Created by Marlon Raskin on 1/2/20.
//  Copyright © 2020 swaap. All rights reserved.
//

import UIKit
import CoreData

class NotificationViewController: UIViewController, ProfileAccessor, ContactsAccessor {

	var profileController: ProfileController?
	var contactsController: ContactsController?

	@IBOutlet private weak var tableView: UITableView!


	lazy var fetchedResultsController: NSFetchedResultsController<ConnectionContact> = {
		let fetchRequest: NSFetchRequest<ConnectionContact> = ConnectionContact.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "connectionStatus", ascending: false)]
		fetchRequest.predicate = NSPredicate(format: "connectionStatus != %i", ContactPendingStatus.connected.rawValue)

		let moc = CoreDataStack.shared.mainContext
		let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
																  managedObjectContext: moc,
																  sectionNameKeyPath: "connectionStatus",
																  cacheName: nil)
		fetchedResultsController.delegate = self
		do {
			try fetchedResultsController.performFetch()
		} catch {
			print("error performing initial fetch for frc: \(error)")
		}
		return fetchedResultsController
	}()

    override func viewDidLoad() {
        super.viewDidLoad()
		tableView.delegate = self
		tableView.dataSource = self
		tableView.separatorStyle = .none
		tableView.allowsSelection = false
		(navigationController?.tabBarController as? RootTabBarController)?.pendingContactsDelegate = self
    }
}

extension NotificationViewController: UITableViewDelegate, UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		fetchedResultsController.sections?.count ?? 0
	}
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		fetchedResultsController.sections?[section].numberOfObjects ?? 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "PendingCell",
													   for: indexPath) as? PendingContactTableViewCell else { return UITableViewCell() }
		cell.profileController = profileController
		let pendingContact = fetchedResultsController.object(at: indexPath)
		cell.connectionContact = pendingContact


		switch indexPath.section {
		case 0:
			cell.isIncoming = true
		default:
			cell.isIncoming = false
		}

		return cell
	}

	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		fetchedResultsController.sectionIndexTitles[section]
	}
}

extension NotificationViewController: NSFetchedResultsControllerDelegate {
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.beginUpdates()
	}

	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.endUpdates()
	}

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
					didChange sectionInfo: NSFetchedResultsSectionInfo,
					atSectionIndex sectionIndex: Int,
					for type: NSFetchedResultsChangeType) {
		let indexSet = IndexSet([sectionIndex])
		switch type {
		case .insert:
			tableView.insertSections(indexSet, with: .automatic)
		case .delete:
			tableView.deleteSections(indexSet, with: .automatic)
		default:
			print(#line, #file, "unexpected NSFetchedResultsChangeType: \(type)")
		}
	}

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
					didChange anObject: Any,
					at indexPath: IndexPath?,
					for type: NSFetchedResultsChangeType,
					newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			guard let newIndexPath = newIndexPath else { return }
			tableView.insertRows(at: [newIndexPath], with: .automatic)
		case .move:
			guard let newIndexPath = newIndexPath, let indexPath = indexPath else { return }
			tableView.moveRow(at: indexPath, to: newIndexPath)
		case .update:
			guard let indexPath = indexPath else { return }
			tableView.reloadRows(at: [indexPath], with: .automatic)
		case .delete:
			guard let indexPath = indexPath else { return }
			tableView.deleteRows(at: [indexPath], with: .automatic)
		@unknown default:
			print(#line, #file, "unknown NSFetchedResultsChangeType: \(type)")
		}
	}

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
		switch sectionName {
		case "0":
			return "Requests Sent"
		default:
			return "Awaiting Your Response"
		}
	}
}

extension NotificationViewController: PendingContactsUpdateDelegate {
	func pendingContactsDidRefresh() {
		let requestCount = contactsController?.pendingIncomingRequests.count ?? 0
		navigationController?.tabBarItem.badgeValue = requestCount > 0 ? "\(requestCount)" : nil
	}
}
