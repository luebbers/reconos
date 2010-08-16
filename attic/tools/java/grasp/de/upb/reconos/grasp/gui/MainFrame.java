package de.upb.reconos.grasp.gui;


import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

import javax.swing.BoxLayout;
import javax.swing.JFrame;
import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;

import de.upb.reconos.grasp.objects.World;
import de.upb.reconos.grasp.physics.ChargeDomain;


public class MainFrame extends JFrame implements ActionListener {

	private static final long serialVersionUID = 1L;
	private RenderPanel renderPanel;
	
	private JMenuItem newItem(String s){
		JMenuItem item = new JMenuItem(s);
		item.addActionListener(this);
		return item;
	}
	
	public MainFrame(String s){
		super(s);
		setSize(640,480);
		
		getContentPane().setLayout(new BoxLayout(getContentPane(),BoxLayout.Y_AXIS));
		
		World w = new World();
		ChargeDomain d = new ChargeDomain();
		w.addChargeDomain(d);
		
		renderPanel = new RenderPanel(w);
		
		JMenuBar menu = new JMenuBar();
		JMenu fileMenu = new JMenu("File");
		fileMenu.add(newItem("Load"));
		fileMenu.add(newItem("Save"));
		fileMenu.addSeparator();
		fileMenu.add(newItem("Exit"));
		menu.add(fileMenu);
		this.setJMenuBar(menu);
		
		getContentPane().add(renderPanel);
	}
	
	public void actionPerformed(ActionEvent e) {
		String cmd = e.getActionCommand().toLowerCase();
		if(cmd.equals("save")){
			FileOutputStream fos;
			try {
				fos = new FileOutputStream("/home/andreas/foo.bar");
				ObjectOutputStream out = new ObjectOutputStream(fos);
				out.writeObject(renderPanel);
				out.close();
			} catch (IOException ex) {
				ex.printStackTrace();
			}
		}
		if(cmd.equals("load")){
			FileInputStream fis;
			try {
				fis = new FileInputStream("/home/andreas/foo.bar");
				ObjectInputStream out = new ObjectInputStream(fis);
				RenderPanel p = (RenderPanel)out.readObject();
				getContentPane().remove(renderPanel);
				getContentPane().add(p);
				renderPanel = p;
				renderPanel.startThread();
				out.close();
			} catch (IOException ex) {
				ex.printStackTrace();
			}
			catch(ClassNotFoundException ex2){
				ex2.printStackTrace();
			}
		}
		if(cmd.equals("exit")){
			dispose();
		}
	}
}
