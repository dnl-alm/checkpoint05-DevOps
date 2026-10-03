package br.com.library.controller;

import br.com.library.dto.request.LivroRequest;
import br.com.library.dto.response.LivroResponse;
import br.com.library.service.LivroService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;
import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping("/livros")
public class LivroController {

    private final LivroService service;

    @GetMapping
    public List<LivroResponse> listar() {
        return service.listar();
    }

    @GetMapping("/{id}")
    public LivroResponse buscar(@PathVariable Long id) {
        return service.buscar(id);
    }

    @PostMapping
    public ResponseEntity<LivroResponse> criar(@RequestBody @Valid LivroRequest dados) {
        LivroResponse criado = service.criar(dados);
        URI uri = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(criado.id()).toUri();
        return ResponseEntity.created(uri).body(criado);
    }

    @PutMapping("/{id}")
    public LivroResponse atualizar(@PathVariable Long id, @RequestBody @Valid LivroRequest dados) {
        return service.atualizar(id, dados);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id) {
        service.excluir(id);
        return ResponseEntity.noContent().build();
    }
}