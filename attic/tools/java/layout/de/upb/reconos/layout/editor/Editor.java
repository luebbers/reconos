package de.upb.reconos.layout.editor;

import java.awt.BorderLayout;
import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.File;
import java.io.IOException;

import javax.swing.JCheckBoxMenuItem;
import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.border.EtchedBorder;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;
import javax.swing.filechooser.FileNameExtensionFilter;

import de.upb.reconos.fpga.DeviceDB;
import de.upb.reconos.fpga.DeviceDescriptionFile;
import de.upb.reconos.fpga.DeviceInfo;
import de.upb.reconos.gui.RowLayout;
import de.upb.reconos.layout.Layout;
import de.upb.reconos.layout.Slot;



public class Editor extends JFrame implements ActionListener, ChangeListener {

	private static final long serialVersionUID = 1L;

	public DeviceRenderPanel renderPanel;
	private JPanel infoPanel;
	private Layout myLayout;
	private File saveFile;
	
	private String newCmd, saveCmd, saveAsCmd, openCmd, exitCmd, aaCmd;
	private JCheckBoxMenuItem aaMenuItem;
	
	private NewDialog diag;
	
	private JMenuItem addMenuItem(JMenu menu, String itemName){
		if(itemName == null){
			menu.addSeparator();
			return null;
		}
		JMenuItem menuItem = new JMenuItem(itemName);
		menuItem.addActionListener(this);
		menuItem.setActionCommand((menu.getText() + "." + itemName).toLowerCase());
		menu.add(menuItem);
		return menuItem;
	}
	
	private JCheckBoxMenuItem addCheckBoxMenuItem(JMenu menu, String itemName, boolean init){
		if(itemName == null){
			menu.addSeparator();
			return null;
		}
		JCheckBoxMenuItem menuItem = new JCheckBoxMenuItem(itemName, init);
		menuItem.addActionListener(this);
		menuItem.setActionCommand((menu.getText() + "." + itemName).toLowerCase());
		menu.add(menuItem);
		return menuItem;
	}
	
	
	public Editor(String s){
		super(s);
		setSize(640,480);
		
		getContentPane().setLayout(new BorderLayout());
		
		setVisible(true);
		
		JMenuBar menuBar = new JMenuBar();
		
		JMenu fileMenu = new JMenu("File");
		newCmd    = addMenuItem(fileMenu,"New Layout").getActionCommand();
		addMenuItem(fileMenu,null);
		saveCmd   = addMenuItem(fileMenu,"Save").getActionCommand();
		saveAsCmd = addMenuItem(fileMenu,"Save As").getActionCommand();
		addMenuItem(fileMenu,null);
		openCmd = addMenuItem(fileMenu,"Open").getActionCommand();
		addMenuItem(fileMenu,null);
		exitCmd = addMenuItem(fileMenu,"Exit").getActionCommand();
		menuBar.add(fileMenu);

		JMenu viewMenu = new JMenu("View");
		aaMenuItem = addCheckBoxMenuItem(viewMenu,"Antialiasing",true);
		aaCmd = aaMenuItem.getActionCommand();
		menuBar.add(viewMenu);
		
		DeviceDescriptionFile fpgaInfo = new DeviceDescriptionFile();
		try {
			fpgaInfo.read(new File("/home/luebbers/work/reconos/trunk/fpgas/xc2vp30.fpga"));
		} catch (IOException e) {
			e.printStackTrace();
			
		}
		
		//this.myLayout = new Layout(new V2PInfo());
		myLayout = new Layout(fpgaInfo);
		renderPanel = new DeviceRenderPanel(this);
		renderPanel.addChangeListener(this);
		
		getContentPane().add(renderPanel,BorderLayout.CENTER);
		
		
		infoPanel = new JPanel();
		infoPanel.setBorder(new EtchedBorder(2));
		getContentPane().add(infoPanel,BorderLayout.EAST);
		
		setJMenuBar(menuBar);
		
		this.setSize(getWidth() - 1, getHeight() - 1);
		this.setSize(getWidth() + 1, getHeight() + 1);
		
		(new SimpleTimer(this,250)).start();
		
		setTitle("Reconos Layout: untitled");
		
		refreshInfoPanel();
		
		invalidate();
		repaint();
	}
	
	private void refreshInfoPanel(){
		infoPanel.removeAll();
		infoPanel.setLayout(new RowLayout());
		
		Dimension dmin = new Dimension(180,0);
		Dimension dmax = new Dimension(180,Short.MAX_VALUE);
		infoPanel.setMaximumSize(dmin);
		infoPanel.setMinimumSize(dmax);
		
		if(getMyLayout().getSlots().size() == 0){
			SlotPanel p = new SlotPanel(null, renderPanel.getFPGAInfo());
			infoPanel.add(p);
			return;
		}
		
		for(Slot s : getMyLayout().getSlots()){
			SlotPanel p = new SlotPanel(s, renderPanel.getFPGAInfo());
			infoPanel.add(p);
		}
	}
	
	public static void main(String[] args) {
		Editor f = new Editor("ucf editor");
		f.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
	}
	
	private boolean saveAs(){
		JFileChooser chooser = new JFileChooser();
	    FileNameExtensionFilter filter = new FileNameExtensionFilter(
	    		"Layout files (*.lyt)", "lyt");
	    chooser.setFileFilter(filter);
	    int returnVal = chooser.showSaveDialog(this);
	    if(returnVal == JFileChooser.APPROVE_OPTION) {
	    	String name = null;
	    	try {
	    		name = chooser.getSelectedFile().getCanonicalPath();
		    	File f = chooser.getSelectedFile();
		    	if(f == null) return false;
		    	
		    	saveFile = f;
		    	
		    	save();
		    	
		    	setTitle("Reconos Layout: " + name);
	    	}
			catch (IOException e1) {
				e1.printStackTrace();
				return false;
			}
			return true;
	    }
	    return false;
	}
	
	private boolean save(){
		if(saveFile == null){
			return saveAs();
		}
		
		try {
			getMyLayout().write(saveFile);
		} catch (IOException e) {
			e.printStackTrace();
			return false;
		}
		return true;
	}
	
	private boolean open(){
		JFileChooser chooser = new JFileChooser();
	    FileNameExtensionFilter filter = new FileNameExtensionFilter(
	    		"Layout files (*.lyt)", "lyt");
	    chooser.setFileFilter(filter);
	    int returnVal = chooser.showOpenDialog(this);
	    if(returnVal == JFileChooser.APPROVE_OPTION) {
	    	String name = null;
	    	try {
	    		name = chooser.getSelectedFile().getCanonicalPath();
		    	File f = chooser.getSelectedFile();
		    	if(f == null) return false;
		    	
		    	myLayout.read(f,getDeviceDB());
				renderPanel.center();
				renderPanel.stateChanged(new ChangeEvent(this));    	
		    	
		    	setTitle("Reconos Layout: " + name);
	    	}
			catch (IOException e1) {
				e1.printStackTrace();
				return false;
			}
			return true;
	    }
	    return false;		
	}
	
	private DeviceDB getDeviceDB(){
		DeviceDB db = new DeviceDB();
		try {
			db.readDir("/home/luebbers/work/reconos/trunk/fpgas");
		} catch (IOException e) {
			e.printStackTrace();
		}
		return db;
	}
	
	private void newLayout(){
		diag = new NewDialog(getDeviceDB(),this);
		diag.setLocationRelativeTo(this);
		diag.addActionListener(this);
		diag.setVisible(true);
		myLayout = new Layout(myLayout.getFPGAInfo());
		renderPanel.stateChanged(new ChangeEvent(this));
	}
	
	public void actionPerformed(ActionEvent e) {
		if(e.getActionCommand().equals(newCmd)){
			newLayout();
			return;
		}
		if(e.getActionCommand().equals(saveAsCmd)){
			saveAs();
			return;
		}
		if(e.getActionCommand().equals(saveCmd)){
			if(saveFile == null) saveAs();
			else save();
			return;
		}
		if(e.getActionCommand().equals(exitCmd)){
			String[] opt = { "Exit", "Save and Exit", "Cancel" };
			int sel = JOptionPane.showOptionDialog(this,
			"Exit without saving?", "Confirmation",
			JOptionPane.YES_NO_CANCEL_OPTION, JOptionPane.QUESTION_MESSAGE,null, opt, opt[0]);
			if(sel == 0){
				System.exit(0);
			}
			if(sel == 1){
				if(!save()) return;
				System.exit(0);
			}
			return;
		}
		if(e.getActionCommand().equals(openCmd)){
			open();
			renderPanel.stateChanged(new ChangeEvent(this));
			return;
		}
		
		if(e.getActionCommand().equals(aaCmd)){
			renderPanel.setAntialiasing(aaMenuItem.isSelected());
			return;
		}
		if(e.getActionCommand().equals("NewDialog.ok")){
			myLayout = new Layout(diag.getChoice());
			renderPanel.center();
		}
	}

	public void stateChanged(ChangeEvent e) {
		this.refreshInfoPanel();
		this.setSize(getWidth() - 1, getHeight() - 1);
		this.setSize(getWidth() + 1, getHeight() + 1);
		this.invalidate();
		this.repaint(1);
	}
	
	public Layout getMyLayout(){
		return myLayout;
	}

	public DeviceInfo getFPGAInfo() {
		return myLayout.getFPGAInfo();
	}
}
