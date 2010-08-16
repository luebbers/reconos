package de.upb.reconos.grasp.gui.menus;


import java.awt.event.ActionEvent;

import de.upb.reconos.grasp.objects.StateNode;
import de.upb.reconos.grasp.objects.World;


public class StateMenu extends BasicMenu {

	private static final long serialVersionUID = 1L;
	private StateNode node;
	
	public StateMenu(World w){
		super(w);
		
		addItem("State Definition");
		addSeparator();
		addItem("Remove This State");
		addSeparator();
		addItem("Options");
	}
	
	public void actionPerformed(ActionEvent e) {
		String cmd = e.getActionCommand().toLowerCase();
		if(cmd.equals("remove this state")){
			world.dissolve(node);
			node = null;
		}
	}

	public void setStateNode(StateNode node) {
		this.node = node;
	}
}
