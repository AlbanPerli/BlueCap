//
//  PeripheralsViewController.swift
//  BlueCapUI
//
//  Created by Troy Stribling on 6/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import CoreBluetooth
import BlueCapKit

let MAX_FAILED_RECONNECTS = 0

class PeripheralsViewController : UITableViewController {
    
    var stopScanBarButtonItem : UIBarButtonItem!
    var startScanBarButtonItem : UIBarButtonItem!
    var connectionSequence : Dictionary<Peripheral, Int> = [:]
    
    struct MainStoryboard {
        static let periphearlCell = "PeripheralCell"
    }
    
    init(coder aDecoder:NSCoder!) {
        super.init(coder:aDecoder)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
        self.stopScanBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Stop, target:self, action:"toggleScan:")
        self.startScanBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Refresh, target:self, action:"toggleScan:")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setScanButton()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue!, sender:AnyObject!) {
    }
    
    // actions
    @IBAction func toggleScan(sender:AnyObject) {
        Logger.debug("toggleScan")
        let central = CentralManager.sharedinstance()
        if (central.isScanning) {
            central.stopScanning()
            central.disconnectAllPeripherals()
        } else {
            central.powerOn(){
                Logger.debug("powerOn Callback")
                central.startScanning(){(peripheral:Peripheral!, rssi:Int) -> () in
                    self.connect(peripheral)
                }
            }
        }
        self.setScanButton()
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView!) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView!, numberOfRowsInSection section:Int) -> Int {
        return CentralManager.sharedinstance().peripherals.count
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.periphearlCell, forIndexPath: indexPath) as PeripheralCell
        let peripheral = CentralManager.sharedinstance().peripherals[indexPath.row]
        cell.nameLabel.text = peripheral.name
        switch(peripheral.state) {
        case .Connected:
            cell.connectingActivityIndicator.stopAnimating()
            cell.accessoryType = .DetailButton
        default:
            cell.connectingActivityIndicator.startAnimating()
            cell.accessoryType = .None
        }
        return cell
    }
    
    // UITableViewDelegate
    
    // PRIVATE INTERFACE
    func setScanButton() {
        if (CentralManager.sharedinstance().isScanning) {
            self.navigationItem.setRightBarButtonItem(self.stopScanBarButtonItem, animated:false)
        } else {
            self.navigationItem.setRightBarButtonItem(self.startScanBarButtonItem, animated:false)
        }
    }
    
    func connect(peripheral:Peripheral) {
        peripheral.connect(Connectorator() {(connectorator:Connectorator) -> () in
            connectorator.onDisconnect() {(periphear:Peripheral) -> () in
                Logger.debug("PeripheralsViewController#onDisconnect")
                peripheral.reconnect()
                self.tableView.reloadData()
            }
            connectorator.onConnect() {(peipheral:Peripheral) -> () in
                Logger.debug("PeripheralsViewController#onConnect")
                self.tableView.reloadData()
            }
            connectorator.onTimeout() {(peripheral:Peripheral) -> () in
                Logger.debug("PeripheralsViewController#onTimeout")
                peripheral.reconnect()
                self.tableView.reloadData()
            }
            connectorator.onForcedDisconnect() {(peripheral:Peripheral) -> () in
                Logger.debug("PeripheralsViewController#onForcedDisconnect")
                self.tableView.reloadData()
            }
        })
    }
}