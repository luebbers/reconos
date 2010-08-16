package de.upb.reconos.layout.editor;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import javax.swing.JMenuItem;
import javax.swing.JPopupMenu;

import de.upb.reconos.gui.Vector2d;






public class ContextMenu extends JPopupMenu implements ActionListener {
	private static final long serialVersionUID = 1L;
	protected Vector2d pos;
	
	public ContextMenu(){
		pos = new Vector2d();
	}
	
	protected void addItem(String s){
		JMenuItem item = new JMenuItem(s);
		item.addActionListener(this);
		this.add(item);
	}
	
	public void setPosition(double x, double y){
		pos.set(x, y);
	}
	
	public void actionPerformed(ActionEvent e){}
}
