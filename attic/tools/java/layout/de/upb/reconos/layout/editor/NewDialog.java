package de.upb.reconos.layout.editor;

import java.awt.BorderLayout;
import java.awt.Frame;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.Set;

import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JSeparator;
import javax.swing.border.EmptyBorder;

import de.upb.reconos.fpga.DeviceDB;
import de.upb.reconos.fpga.DeviceInfo;
import de.upb.reconos.gui.RowLayout;

public class NewDialog extends JDialog implements ActionListener {

	JComboBox familyChooser;
	JComboBox deviceChooser;
	JButton okButton;
	boolean ok;
	DeviceDB db;
	
	public NewDialog(DeviceDB db, Frame owner){
		super(owner,true);
		this.db = db;
		familyChooser = new JComboBox();
		deviceChooser = new JComboBox();
		
		Set<String> families = db.getFamilies();
		for(String s : families){
			familyChooser.addItem(s);
		}
		updateChoice();
		
		familyChooser.addActionListener(this);
		
		JPanel rootPanel = new JPanel();
		JPanel buttonPanel = new JPanel();
		
		rootPanel.setLayout(new RowLayout(5));
		rootPanel.setBorder(new EmptyBorder(10,2,5,2));
		
		rootPanel.add(new JLabel("Device Family:"));
		rootPanel.add(familyChooser);
		rootPanel.add(new JSeparator());
		rootPanel.add(new JLabel("Device:"));
		rootPanel.add(deviceChooser);
		rootPanel.add(new JSeparator());
		rootPanel.add(buttonPanel);
		 
		
		okButton = new JButton("Ok");
		okButton.setActionCommand("NewDialog.ok");
		okButton.addActionListener(this);
		JButton cancelButton = new JButton("Cancel");
		cancelButton.addActionListener(this);
		buttonPanel.setLayout(new BorderLayout());
		buttonPanel.add(cancelButton,BorderLayout.WEST);
		buttonPanel.add(okButton,BorderLayout.EAST);
		
		getContentPane().add(rootPanel);
		
		pack();
		setSize(this.getWidth()*2, this.getHeight());
		setResizable(false);
		
		ok = false;
	}
	
	private void updateChoice(){
		String family = (String)familyChooser.getSelectedItem();
		Set<String> devices = db.getDevices(family);
		
		deviceChooser.removeAllItems();
		for(String s : devices){
			deviceChooser.addItem(s);
		}
	}

	public void actionPerformed(ActionEvent e) {
		updateChoice();
		if(e.getActionCommand().equals("NewDialog.ok")){
			setVisible(false);
		}
		if(e.getActionCommand().equals("Cancel")){
			setVisible(false);
		}
		
	}
	
	public void addActionListener(ActionListener l){
		okButton.addActionListener(l);
	}
	
	public DeviceInfo getChoice(){
		return db.getDevice((String)deviceChooser.getSelectedItem());
	}
}
