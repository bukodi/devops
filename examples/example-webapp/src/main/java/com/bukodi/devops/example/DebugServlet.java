package com.bukodi.devops.example;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.logging.Logger;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Servlet implementation class DebugServlet
 */
public class DebugServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	protected final static Logger LOG = Logger.getAnonymousLogger();
	
    /**
     * Default constructor. 
     */
    public DebugServlet() {
    	LOG.finer("Created");
    }

	/**
	 * @see Servlet#init(ServletConfig)
	 */
	public void init(ServletConfig config) throws ServletException {
    	LOG.finer("Init");
	}

	/**
	 * @see Servlet#destroy()
	 */
	public void destroy() {
    	LOG.finer("Destroy");
	}

	/**
	 * @see HttpServlet#service(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void service(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		response.setStatus(200);
		PrintWriter pw = response.getWriter();
		pw.println("<html>\n  <body>");
		pw.println("<p>Hello</p>");
		pw.println("  </body>\n</html>");
	}

}
