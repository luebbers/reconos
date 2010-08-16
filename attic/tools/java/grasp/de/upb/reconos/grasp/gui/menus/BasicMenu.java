package de.upb.reconos.grasp.gui.menus;


import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import javax.swing.JMenuItem;
import javax.swing.JPopupMenu;

import de.upb.reconos.grasp.math.Vector2d;
import de.upb.reconos.grasp.objects.World;


public class BasicMenu extends JPopupMenu implements ActionListener{

	private static final long serialVersionUID = 1L;
	protected World world;
	protected Vector2d worldPosition;
	
	public BasicMenu(World w){
		world = w;
		worldPosition = new Vector2d();
	}
	
	public void setWorldPosition(double x, double y){
		worldPosition.set(x, y);
	}
	
	protected void addItem(String s){
		JMenuItem item = new JMenuItem(s);
		item.addActionListener(this);
		this.add(item);
	}
	
	public void actionPerformed(ActionEvent e){}
}
