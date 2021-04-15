import UIKit

protocol TableViewDataSource: AnyObject {
    func numberOfRowInTableView(_ tableView: TableView) -> Int
    func tableView(_ tableView: TableView, textForRow row: Int) -> String
}

class TableView: UIScrollView {
    weak var dataSource: TableViewDataSource?
    var cells : [TableCell] = []
    let sizeOfCell = 40
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        let size = dataSource?.numberOfRowInTableView(self) ?? 0
        if contentSize.height != CGFloat(size * sizeOfCell) || contentSize.width != self.bounds.width {
            contentSize = CGSize(width: self.bounds.width, height: CGFloat(size * sizeOfCell))
            for cell in cells {
                cell.frame = CGRect(x: 0, y: cell.frame.minY, width: contentSize.width, height: CGFloat(sizeOfCell))
            }
        }
        
        let shouldBeCellsWithExtra = Int(bounds.height) / sizeOfCell + 2
        if cells.count < shouldBeCellsWithExtra {
            for i in cells.count..<shouldBeCellsWithExtra {
                let cell = TableCell(frame: CGRect(x: 0, y: i * sizeOfCell, width: Int(contentSize.width), height: sizeOfCell))
                let text = dataSource?.tableView(self, textForRow: i) ?? "NOPE"
                cell.update(text: text)
                if cell.frame.minY >= bounds.minY && cell.frame.maxY <= bounds.maxY {
                    addSubview(cell)
                }
                cells.append(cell)
            }
            print(cells.count)
        }
        
        let i = (bounds.minY > 0) ? bounds.minY : 0
        let max = (bounds.maxY < contentSize.height) ? bounds.maxY : contentSize.height
        for cell in cells {
            if cell.frame.maxY < i || cell.frame.minY > max {
                cell.removeFromSuperview()
            }
        }
        
        var minY = Int(i) / sizeOfCell * sizeOfCell
        let maxY = Int(max) / sizeOfCell * sizeOfCell + ((Int(max) % sizeOfCell == 0) ? 0 : sizeOfCell)
        while minY < maxY {
            let text = dataSource?.tableView(self, textForRow: minY / sizeOfCell) ?? "NOPE"
            
            let cell = cells[(minY / sizeOfCell) % cells.count]
            if cell.frame.minY != CGFloat(minY) {
                cell.update(text: text)
                cell.frame = CGRect(x: 0, y: minY, width: Int(contentSize.width), height: sizeOfCell)
            }
            if cell.superview == nil {
                addSubview(cell)
            }
            minY += sizeOfCell
        }
    }
}
