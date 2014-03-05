package com.bukodi.devops.example;

import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.io.PrintWriter;
import java.io.StringWriter;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.junit.Before;
import org.junit.Test;

public class DebugServletTest {

	@Before
	public void setUp() throws Exception {
	}

	@Test
	public void testService() throws Exception {
		DebugServlet servlet = new DebugServlet();
		HttpServletRequest request = mock( HttpServletRequest.class);
		HttpServletResponse response = mock(HttpServletResponse.class);
		StringWriter outputBuff = new StringWriter();
		when(response.getWriter()).thenReturn(new PrintWriter(outputBuff));	
		servlet.service(request, response);
		assertTrue("Response contains hello", outputBuff.toString().contains("Hello"));
	}

}
