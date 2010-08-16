package de.upb.reconos.grasp.gui.menus;


import java.awt.event.ActionEvent;

import de.upb.reconos.grasp.objects.PortNode;
import de.upb.reconos.grasp.objects.World;


public class PortMenu extends BasicMenu {

	private static final long serialVersionUID = 1L;
	private PortNode node;
	
	public PortMenu(World w){
		super(w);
		
		addItem("Port Definition");
		addSeparator();
		addItem("Remove This Port");
		addSeparator();
		addItem("Options");
	}
	
	public void actionPerformed(ActionEvent e) {
		String cmd = e.getActionCommand().toLowerCase();
		if(cmd.equals("remove this port")){
			world.dissolve(node);
			node = null;
		}
	}

	public void setPortNode(PortNode node) {
		this.node = node;
	}
}
