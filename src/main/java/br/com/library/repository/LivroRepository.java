package br.com.library.repository;

import br.com.library.entity.Livro;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface LivroRepository extends JpaRepository<Livro, Long> {
    List<Livro> findByAutorId(Long autorId);

    boolean existsByAutorId(Long autorId);
}
