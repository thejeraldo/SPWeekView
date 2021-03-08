//
//  SPWeekView.swift
//  SPWeekView
//
//  Created by jerald on 25/1/21.
//  Copyright © 2019 SPECTRUM. All rights reserved.
//

import UIKit

/// The methods adopted by the object you use to manage user interactions with items in a week view.
public protocol SPWeekViewDelegate: class {
  
  /// Allows the delegate to configure the cell appearance.
  func configureCell(_ cell: DateCell, for state: DateCell.State)
  
  /// Tells the delegate that a date has been selected.
  func weekView(_ weekView: SPWeekView, didSelect date: Date)
  
  /// Tells the delegate that the collection view did scroll and returns the indexPaths of the visible items.
  func weekView(_ weekView: SPWeekView, didScrollToIndexPaths indexPaths: [IndexPath])
  
  /// Asks the delegate for the dates that should be marked with events.
  func datesWithEvents() -> [Date]
}

/// A view that manages a collection horizontally scrollable dates that are grouped per week (7 days).
public class SPWeekView: UIView {
  
  // MARK: - Public Properties
  
  /// The date items for the view.
  public var dates = [Date]()
  
  /// The current date for the view.
  public var currentDate = Date()
  
  /// The currently selected date for the view.
  public var selectedDate: Date?
  
  /// The type of scrolling for the week view.
  public enum ScrollType {
    case continous
    case paginated
  }
  
  /// The type of scrolling for the week view.
  /// continous will set the scrolling to be continous.
  /// paginated will set the scrolling to be paginated by 7 days a week.
  public var scrollType: ScrollType = .continous
  
  /// The object that acts as the delegate of the week view.
  public weak var delegate: SPWeekViewDelegate?
  
  // MARK: - Private Properties
  
  /// The Gregorian calendar for the date calculations.
  private let calendar = Calendar(identifier: .gregorian)
  
  private lazy var collectionView: UICollectionView = {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
    collectionView.alwaysBounceVertical = false
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.register(DateCell.self, forCellWithReuseIdentifier: "dateCell")
    return collectionView
  }()
  
  public enum Section: Int, Hashable {
    case main
  }
  
  public typealias DataSource = UICollectionViewDiffableDataSource<Section, Date>
  
  private typealias SnapShot = NSDiffableDataSourceSnapshot<Section, Date>
  
  private var snapshot = SnapShot()
  
  public lazy var dataSource: DataSource = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, date -> UICollectionViewCell? in
    guard let self = self else { return nil }
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dateCell", for: indexPath) as! DateCell
    let calendar = Calendar(identifier: .gregorian)
    let isToday = calendar.isDateInToday(date)
    cell.configureWith(date, isToday: isToday)
    
    var state: DateCell.State = .normal(isToday: isToday)
    if date == self.selectedDate {
      state = .selected
    }
    self.delegate?.configureCell(cell, for: state)
    
    let datesWithEvents = self.delegate?.datesWithEvents()
    let shouldShowMarkerView = datesWithEvents?.contains(date) == true
    if !shouldShowMarkerView {
      cell.eventIndicatorView.backgroundColor = .clear
    }
    
    return cell
  }
  
  // MARK: - Init
  
  public init(dates: [Date]) {
    super.init(frame: .zero)
    self.dates = dates
    setupViews()
    reloadData()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupViews()
    reloadData()
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    collectionView.collectionViewLayout.invalidateLayout()
    guard let selectedDate = selectedDate else { return }
    scrollToDate(selectedDate)
  }
  
}

// MARK: - Private Methods

extension SPWeekView {
  
  /// Setup views and constraints.
  private func setupViews() {
    collectionView.delegate = self
    addSubview(collectionView)
    collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
    collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true
    collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4).isActive = true
    collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4).isActive = true
    collectionView.backgroundColor = .white
  }
  
  /// Returns the layout for the week view.
  /// Provide the layoutWidth for iOS 13 and below.
  func createLayout(layoutWidth: CGFloat) -> UICollectionViewLayout {
    // Item
    let padding: CGFloat = 8.0
    var itemLayoutWidthDimension: NSCollectionLayoutDimension = .absolute((layoutWidth - padding) / 7)
    if #available(iOS 14.0, *) { itemLayoutWidthDimension = .fractionalWidth(1 / 7) }
    let itemSize = NSCollectionLayoutSize(widthDimension: itemLayoutWidthDimension, heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    
    // Group
    let width: CGFloat = scrollType == .continous ? 1.175 : 1.0
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(width),
                                           heightDimension: .fractionalHeight(1.0))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                   subitems: [item])
    
    // Section
    let section = NSCollectionLayoutSection(group: group)
    section.orthogonalScrollingBehavior = scrollType == .continous ? .continuous : .paging
    section.visibleItemsInvalidationHandler = { [weak self] items, point, env in
      guard let self = self else { return }
      let indexPaths = items.map(\.indexPath)
      self.delegate?.weekView(self, didScrollToIndexPaths: indexPaths)
    }
    
    // Layout
    let layout = UICollectionViewCompositionalLayout(section: section)
    return layout
  }
}

// MARK: - Public Methods

public extension SPWeekView {
  
  /// Reload the data for the week view.
  func reloadData() {
    snapshot = SnapShot()
    snapshot.appendSections([Section.main])
    snapshot.appendItems(dates, toSection: .main)
    dataSource.apply(snapshot, animatingDifferences: false)
  }
  
  /// Set the selected date for the week view.
  /// - Parameters:
  ///   - date: The date to be the new selected date.
  ///   - animated: Specify true to animate the date selection.
  func selectDate(_ date: Date, animated: Bool) {
    self.selectedDate = date
    delegate?.weekView(self, didSelect: date)
    collectionView.reloadData()
    guard let indexPath = dataSource.indexPath(for: self.selectedDate!) else { return }
    guard let cell = collectionView.cellForItem(at: indexPath) as? DateCell else { return }
    guard animated else { return }
    UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: [ .autoreverse ]) {
      cell.selectionView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
    } completion: { _ in
      cell.selectionView.transform = .identity
    }
  }
  
  
  /// Scroll the week view until the specified date is visible.
  /// - Parameters:
  ///   - date: The date to scroll to.
  ///   - animated: Specify true to animate the date scrolling.
  func scrollToDate(_ date: Date, animated: Bool = false) {
    DispatchQueue.main.async { [weak self] in
      guard let index = self?.snapshot.indexOfItem(date) else { return }
      let indexPath = IndexPath(row: index, section: Section.main.rawValue)
      self?.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }
  }
  
}

// MARK: - UICollectionViewDelegate

extension SPWeekView: UICollectionViewDelegate {
  
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    // Set the selected date and do some internal animations.
    guard let date = dataSource.itemIdentifier(for: indexPath) else { return }
    selectDate(date, animated: self.selectedDate == date)
    guard let selectedDate = selectedDate else { return }
    delegate?.weekView(self, didSelect: selectedDate)
  }

}

extension SPWeekView {
  
  /// Returns dates 1 month before and after the specified date.
  /// With the start and end date rounding down and up to Sunday and Saturday respectively.
  public static func generateDates(fromDate date: Date) -> [Date] {
    let calendar = Calendar(identifier: .gregorian)
    let now = calendar.startOfDay(for: date)
    
    // Calculate the preceeding dates.
    var start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
    start = calendar.date(byAdding: .month, value: -1, to: now)!
    start = calendar.date(byAdding: .day, value: ((calendar.component(.weekday, from: start) - 1) % 7) * -1, to: start)!
    
    // Calculate the proceeding dates.
    let comps = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
    var end = calendar.date(byAdding: .weekOfYear, value: 1, to: comps)!
    end = calendar.date(byAdding: .month, value: 1, to: now)!
    end = calendar.date(byAdding: .day, value: ((calendar.component(.weekday, from: end) - 1) % 7) - 2, to: end)!
    
    // Make past dates.
    var dates = [Date]()
    var tempDate = now
    while tempDate >= start {
      if !dates.contains(tempDate) { dates.append(tempDate) }
      if let newDate = calendar.date(byAdding: .day, value: -1, to: tempDate) {
        tempDate = calendar.startOfDay(for: newDate)
      }
    }
    
    // Make future dates.
    tempDate = now
    while tempDate <= end {
      if !dates.contains(tempDate) { dates.append(tempDate) }
      if let newDate = calendar.date(byAdding: .day, value: 1, to: tempDate) {
        tempDate = calendar.startOfDay(for: newDate)
      }
    }
    
    return dates.sorted()
  }
}


