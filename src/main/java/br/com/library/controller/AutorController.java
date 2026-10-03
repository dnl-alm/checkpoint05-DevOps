package br.com.library.controller;

import br.com.library.dto.request.AutorRequest;
import br.com.library.dto.response.AutorResponse;
import br.com.library.dto.response.LivroResponse;
import br.com.library.service.AutorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;
import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping("/autores")
public class AutorController {

    private final AutorService service;

    @GetMapping
    public List<AutorResponse> listar() {
        return service.listar();
    }

    @GetMapping("/{id}")
    public AutorResponse buscar(@PathVariable Long id) {
        return service.buscar(id);
    }

    @GetMapping("/{id}/livros")
    public List<LivroResponse> livros(@PathVariable Long id) {
        return service.listarLivros(id);
    }

    @PostMapping
    public ResponseEntity<AutorResponse> criar(@RequestBody @Valid AutorRequest dados) {
        AutorResponse criado = service.criar(dados);
        URI uri = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(criado.id()).toUri();
        return ResponseEntity.created(uri).body(criado);
    }

    @PutMapping("/{id}")
    public AutorResponse atualizar(@PathVariable Long id, @RequestBody @Valid AutorRequest dados) {
        return service.atualizar(id, dados);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id) {
        service.excluir(id);
        return ResponseEntity.noContent().build();
    }
}