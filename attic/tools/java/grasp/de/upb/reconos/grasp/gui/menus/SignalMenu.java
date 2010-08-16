package de.upb.reconos.grasp.gui.menus;


import java.awt.event.ActionEvent;

import de.upb.reconos.grasp.objects.SignalNode;
import de.upb.reconos.grasp.objects.World;


public class SignalMenu extends BasicMenu {

	private static final long serialVersionUID = 1L;
	private SignalNode node;
	
	public SignalMenu(World w){
		super(w);
		
		addItem("Signal Definition");
		addSeparator();
		addItem("Remove This Signal");
		addSeparator();
		addItem("Options");
	}
	
	public void actionPerformed(ActionEvent e) {
		String cmd = e.getActionCommand().toLowerCase();
		if(cmd.equals("remove this signal")){
			world.dissolve(node);
			node = null;
		}
	}

	public void setSignalNode(SignalNode node) {
		this.node = node;
	}
}
