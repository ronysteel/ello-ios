//
//  FakeProfileHeaderCellSizeCalculator.swift
//  Ello
//
//  Created by Ryan Boyajian on 3/24/15.
//  Copyright (c) 2015 Ello. All rights reserved.
//

import Ello


public class FakeProfileHeaderCellSizeCalculator: ProfileHeaderCellSizeCalculator {

    override public func processCells(cellItems:[StreamCellItem], withWidth: CGFloat, completion:ElloEmptyCompletion) {
        self.completion = completion
        self.cellItems = cellItems
        for item in cellItems {
            item.oneColumnCellHeight = AppSetup.Size.calculatorHeight
            item.multiColumnCellHeight = AppSetup.Size.calculatorHeight
        }
        completion()
    }
}
