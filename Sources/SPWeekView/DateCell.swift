//
//  DateCell.swift
//  SPWeekView
//
//  Created by jerald on 25/1/21.
//  Copyright © 2019 SPECTRUM. All rights reserved.
//

import UIKit

public class DateCell: UICollectionViewCell {
  
  // MARK: - Public Properties
  
  public enum State {
    case normal(isToday: Bool)
    case selected
  }
  
  // MARK: - UIKit
  
  public lazy var dateLabel: UILabel = {
    let label = UILabel()
    label.textColor = .label
    label.font = UIFont.systemFont(ofSize: 25, weight: .bold)
    label.textAlignment = .center
    return label
  }()
  
  public lazy var dayLabel: UILabel = {
    let label = UILabel()
    label.textColor = .label
    label.font = UIFont.systemFont(ofSize: 14, weight: .light)
    label.textAlignment = .center
    return label
  }()
  
  public lazy var selectionView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer.borderWidth = 1
    view.layer.borderColor = UIColor.systemFill.cgColor
    view.layer.cornerCurve = .circular
    return view
  }()
  
  public lazy var eventIndicatorView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.systemFill
    view.layer.cornerCurve = .circular
    view.clipsToBounds = true
    view.layer.masksToBounds = true
    return view
  }()
  
  // MARK: - Private Properties
  
  private let df = DateFormatter()
  
  // MARK: - Init
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder: NSCoder) {
    fatalError()
  }
  
  // MARK: - Public Methods
  
  public func configureWith(_ date: Date, isToday: Bool) {
    // Date Label
    df.dateFormat = "d"
    dateLabel.text = df.string(from: date)
    
    // Day Label
    df.dateFormat = "eee"
    dayLabel.text = isToday ? "Today" : df.string(from: date).lowercased()
    
    // Constraints
    addSubview(selectionView)
    selectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
    selectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
    selectionView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
    selectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
    selectionView.isHidden = true
    
    let eventIndicatorSize: CGFloat = 4.0
    eventIndicatorView.widthAnchor.constraint(equalToConstant: eventIndicatorSize).isActive = true
    eventIndicatorView.heightAnchor.constraint(equalToConstant: eventIndicatorSize).isActive = true
    eventIndicatorView.layer.cornerRadius = eventIndicatorSize * 0.5
    
    let stackView = UIStackView(arrangedSubviews: [ dateLabel, dayLabel, eventIndicatorView ])
    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.spacing = 0
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
    stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
    stackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    
    stackView.setCustomSpacing(4.0, after: dayLabel)
    
    // For debugging purposes:
    /*
    let view = UIView(frame: .init(x: 0, y: 0, width: 2, height: 999))
    addSubview(view)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    view.widthAnchor.constraint(equalToConstant: 1).isActive = true
    view.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    view.topAnchor.constraint(equalTo: topAnchor).isActive = true
    view.backgroundColor = .clear*/
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    selectionView.layer.cornerRadius = frame.width * 0.5
  }
}
