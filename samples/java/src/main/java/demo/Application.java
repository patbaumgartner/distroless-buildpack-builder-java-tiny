package demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** Distroless sample application. */
@SpringBootApplication
@RestController
public class Application {

  /**
   * Starts the sample application.
   *
   * @param args command-line arguments forwarded to Spring Boot
   */
  public static void main(String[] args) {
    SpringApplication.run(Application.class, args);
  }

  /**
   * Handles {@code GET /}.
   *
   * @return the greeting asserted by the builder integration tests
   */
  @GetMapping("/")
  public String hello() {
    return "Hello from distroless buildpack builder!";
  }

  /**
   * Handles {@code GET /health}.
   *
   * @return {@code OK} once the application is serving traffic
   */
  @GetMapping("/health")
  public String health() {
    return "OK";
  }
}
